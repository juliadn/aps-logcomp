from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional

@dataclass
class Instr:
    op: str
    args: Tuple[str, ...]

class AirConditioningVM:
    """
    VM para simular um ar-condicionado.
    
    Registradores:
      - TEMP: temperatura definida
      - VEL: velocidade do ventilador
    
    Sensores (read-only):
      - TEMP_AMB: temperatura ambiente
      - HUMID: umidade do ar
      - ENERGY: nível de energia disponível
    
    Instruções:
      SET reg n       ; define valor do registrador
      MOV reg1 reg2   ; copia reg2 para reg1
      ADD reg1 reg2   ; reg1 := reg1 + reg2
      ADDI reg n      ; reg := reg + n
      SUB reg1 reg2   ; reg1 := reg1 - reg2
      SUBI reg n      ; reg := reg - n
      MUL reg1 reg2   ; reg1 := reg1 * reg2
      MULI reg n      ; reg := reg * n
      DIV reg1 reg2   ; reg1 := reg1 / reg2
      DIVI reg n      ; reg := reg / n
      INC reg         ; reg := reg + 1
      DEC reg         ; reg := reg - 1
      DECJZ reg label ; if reg == 0: jump, else: reg--
      GOTO label      ; salto incondicional
      JEQ r1 r2 label ; salta se r1 == r2
      JNE r1 r2 label ; salta se r1 != r2
      JGT r1 r2 label ; salta se r1 > r2
      JLT r1 r2 label ; salta se r1 < r2
      JGE r1 r2 label ; salta se r1 >= r2
      JLE r1 r2 label ; salta se r1 <= r2
      ON              ; liga o ar-condicionado
      OFF             ; desliga o ar-condicionado
      PRINT arg       ; imprime registrador, sensor ou string
      PUSH reg        ; empilha valor
      POP reg         ; desempilha valor
      HALT            ; para execução
    """
    
    def __init__(self):
        
        self.registers: Dict[str, int] = {
            "TEMP": 0,
            "VEL": 0,
        }
        
        self.sensors: Dict[str, int] = {
            "TEMP_AMB": 28,   # temperatura ambiente inicial
            "HUMID": 60,      # umidade inicial (%)
            "ENERGY": 100,    # energia disponível (%)
        }
        
        self.variables: Dict[str, int] = {}
        
        self.temp_regs: Dict[str, int] = {
            "_cmp1": 0,
            "_cmp2": 0,
            "_tmp": 0,
        }
        
        self.is_on: bool = False
        self.program: List[Instr] = []
        self.labels: Dict[str, int] = {}
        self.pc: int = 0
        self.halted: bool = False
        self.steps: int = 0
        self.stack: List[int] = []
        self.ticks: int = 0
        
    def _get_value(self, name: str) -> int:
        """Obtém valor de registrador, sensor, variável ou constante."""
        try:
            return int(name)
        except ValueError:
            pass
        
        # Registradores principais
        if name in self.registers:
            return self.registers[name]
        
        # Sensores
        if name in self.sensors:
            return self.sensors[name]
        
        # Registradores temporários
        if name in self.temp_regs:
            return self.temp_regs[name]
        
        # Variáveis do usuário
        if name in self.variables:
            return self.variables[name]
        
        # Variável não existe, cria com 0
        self.variables[name] = 0
        return 0
    
    def _set_value(self, name: str, value: int):
        if name in self.sensors:
            raise RuntimeError(f"Sensor '{name}' é somente leitura!")
        
        if name in self.registers:
            self.registers[name] = value
            return
        
        if name in self.temp_regs:
            self.temp_regs[name] = value
            return
        
        self.variables[name] = value
    
    def load_program(self, source: str):
        self.program.clear()
        self.labels.clear()
        self.stack.clear()
        self.variables.clear()
        self.pc = 0
        self.halted = False
        self.steps = 0
        self.ticks = 0
        self.is_on = False
        
        # Reset registradores
        self.registers = {"TEMP": 0, "VEL": 0}
        self.temp_regs = {"_cmp1": 0, "_cmp2": 0, "_tmp": 0}
        
        lines = source.splitlines()
        
        idx = 0
        for raw in lines:
            line = raw.split(';')[0].strip()
            if not line:
                continue
            if line.endswith(':'):
                label = line[:-1].strip()
                if label in self.labels:
                    raise ValueError(f"Label duplicado: {label}")
                self.labels[label] = idx
            else:
                idx += 1
        
        for raw in lines:
            line = raw.split(';')[0].strip()
            if not line or line.endswith(':'):
                continue
            
            
            if 'PRINT "' in line or "PRINT '" in line:
                parts = line.split(' ', 1)
                op = parts[0].upper()
                args = (parts[1],) if len(parts) > 1 else ()
            else:
                tokens = line.replace(',', ' ').split()
                op = tokens[0].upper()
                args = tuple(tokens[1:])
            
            self.program.append(Instr(op, args))
    
    def _update_environment(self):
        if self.is_on:
            temp_target = self.registers["TEMP"]
            vel = self.registers["VEL"]
            current_temp = self.sensors["TEMP_AMB"]
            
            # Ar ligado tenta aproximar temperatura ambiente da temperatura alvo
            if current_temp > temp_target:
                cooling = min(vel * 0.5, current_temp - temp_target)
                self.sensors["TEMP_AMB"] = int(current_temp - cooling)
            elif current_temp < temp_target:
                heating = min(vel * 0.3, temp_target - current_temp)
                self.sensors["TEMP_AMB"] = int(current_temp + heating)
            
            energy_cost = vel * 0.1
            self.sensors["ENERGY"] = max(0, int(self.sensors["ENERGY"] - energy_cost))
            
            # Umidade diminui com ar ligado
            if self.sensors["HUMID"] > 30:
                self.sensors["HUMID"] -= 1
        else:
            # Ar desligado: temperatura ambiente volta ao normal lentamente
            if self.sensors["TEMP_AMB"] < 28:
                self.sensors["TEMP_AMB"] += 1
            
            # Umidade normaliza
            if self.sensors["HUMID"] < 60:
                self.sensors["HUMID"] += 1
    
    def step(self):
        """Executa uma instrução."""
        if self.halted:
            return
        
        if not (0 <= self.pc < len(self.program)):
            self.halted = True
            return
        
        instr = self.program[self.pc]
        self.steps += 1
        self.ticks += 1
        
        # Atualiza ambiente a cada tick
        if self.ticks % 10 == 0:
            self._update_environment()
        
        op = instr.op
        args = instr.args
        
        if op == "SET":
            reg, val = args[0], int(args[1])
            self._set_value(reg, val)
            self.pc += 1
            
        elif op == "MOV":
            reg1, reg2 = args[0], args[1]
            self._set_value(reg1, self._get_value(reg2))
            self.pc += 1
            
        elif op == "ADD":
            reg1, reg2 = args[0], args[1]
            self._set_value(reg1, self._get_value(reg1) + self._get_value(reg2))
            self.pc += 1
            
        elif op == "ADDI":
            reg, val = args[0], int(args[1])
            self._set_value(reg, self._get_value(reg) + val)
            self.pc += 1
            
        elif op == "SUB":
            reg1, reg2 = args[0], args[1]
            self._set_value(reg1, self._get_value(reg1) - self._get_value(reg2))
            self.pc += 1
            
        elif op == "SUBI":
            reg, val = args[0], int(args[1])
            self._set_value(reg, self._get_value(reg) - val)
            self.pc += 1
            
        elif op == "MUL":
            reg1, reg2 = args[0], args[1]
            self._set_value(reg1, self._get_value(reg1) * self._get_value(reg2))
            self.pc += 1
            
        elif op == "MULI":
            reg, val = args[0], int(args[1])
            self._set_value(reg, self._get_value(reg) * val)
            self.pc += 1
            
        elif op == "DIV":
            reg1, reg2 = args[0], args[1]
            divisor = self._get_value(reg2)
            if divisor == 0:
                raise RuntimeError("Divisão por zero!")
            self._set_value(reg1, self._get_value(reg1) // divisor)
            self.pc += 1
            
        elif op == "DIVI":
            reg, val = args[0], int(args[1])
            if val == 0:
                raise RuntimeError("Divisão por zero!")
            self._set_value(reg, self._get_value(reg) // val)
            self.pc += 1
            
        elif op == "INC":
            reg = args[0]
            self._set_value(reg, self._get_value(reg) + 1)
            self.pc += 1
            
        elif op == "DEC":
            reg = args[0]
            self._set_value(reg, self._get_value(reg) - 1)
            self.pc += 1
            
        elif op == "DECJZ":
            reg, label = args[0], args[1]
            if self._get_value(reg) == 0:
                if label not in self.labels:
                    raise ValueError(f"Label desconhecido: {label}")
                self.pc = self.labels[label]
            else:
                self._set_value(reg, self._get_value(reg) - 1)
                self.pc += 1
                
        elif op == "GOTO":
            label = args[0]
            if label not in self.labels:
                raise ValueError(f"Label desconhecido: {label}")
            self.pc = self.labels[label]
            
        elif op == "JEQ":
            r1, r2, label = args[0], args[1], args[2]
            if self._get_value(r1) == self._get_value(r2):
                self.pc = self.labels[label]
            else:
                self.pc += 1
                
        elif op == "JNE":
            r1, r2, label = args[0], args[1], args[2]
            if self._get_value(r1) != self._get_value(r2):
                self.pc = self.labels[label]
            else:
                self.pc += 1
                
        elif op == "JGT":
            r1, r2, label = args[0], args[1], args[2]
            if self._get_value(r1) > self._get_value(r2):
                self.pc = self.labels[label]
            else:
                self.pc += 1
                
        elif op == "JLT":
            r1, r2, label = args[0], args[1], args[2]
            if self._get_value(r1) < self._get_value(r2):
                self.pc = self.labels[label]
            else:
                self.pc += 1
                
        elif op == "JGE":
            r1, r2, label = args[0], args[1], args[2]
            if self._get_value(r1) >= self._get_value(r2):
                self.pc = self.labels[label]
            else:
                self.pc += 1
                
        elif op == "JLE":
            r1, r2, label = args[0], args[1], args[2]
            if self._get_value(r1) <= self._get_value(r2):
                self.pc = self.labels[label]
            else:
                self.pc += 1
                
        elif op == "ON":
            self.is_on = True
            print("🌀 Ar-condicionado LIGADO")
            self.pc += 1
            
        elif op == "OFF":
            self.is_on = False
            print("⭕ Ar-condicionado DESLIGADO")
            self.pc += 1
            
        elif op == "PRINT":
            arg = args[0] if args else ""
            if arg.startswith('"') and arg.endswith('"'):
                print(arg[1:-1])
            elif arg.startswith("'") and arg.endswith("'"):
                print(arg[1:-1])
            else:
                val = self._get_value(arg)
                print(f"{arg}: {val}")
            self.pc += 1
            
        elif op == "PUSH":
            reg = args[0]
            self.stack.append(self._get_value(reg))
            self.pc += 1
            
        elif op == "POP":
            reg = args[0]
            if not self.stack:
                raise RuntimeError("Stack vazia!")
            self._set_value(reg, self.stack.pop())
            self.pc += 1
            
        elif op == "HALT":
            print("\n✅ Programa finalizado!")
            self.halted = True
            
        else:
            raise ValueError(f"Instrução desconhecida: {op}")
    
    def run(self, max_steps: Optional[int] = 10000):
        """Executa programa até HALT ou limite de passos."""
        while not self.halted:
            if max_steps and self.steps >= max_steps:
                raise RuntimeError("Limite de passos atingido (loop infinito?)")
            self.step()
    
    def state(self) -> Dict:
        """Retorna estado atual da VM."""
        return {
            "is_on": self.is_on,
            "registers": dict(self.registers),
            "sensors": dict(self.sensors),
            "variables": dict(self.variables),
            "stack": list(self.stack),
            "steps": self.steps,
        }


# === MAIN ===
if __name__ == "__main__":
    import sys
    
    vm = AirConditioningVM()
    
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        try:
            with open(filename, 'r') as f:
                program = f.read()
            
            print(f"=== AirConditioningVM ===")
            print(f"Executando: {filename}\n")
            
            vm.load_program(program)
            vm.run()
            
            print(f"\n=== Estado Final ===")
            state = vm.state()
            print(f"Ar ligado: {'Sim' if state['is_on'] else 'Não'}")
            print(f"Registradores: TEMP={state['registers']['TEMP']}, VEL={state['registers']['VEL']}")
            print(f"Sensores: TEMP_AMB={state['sensors']['TEMP_AMB']}, HUMID={state['sensors']['HUMID']}, ENERGY={state['sensors']['ENERGY']}")
            if state['variables']:
                print(f"Variáveis: {state['variables']}")
            print(f"Passos executados: {state['steps']}")
            
        except FileNotFoundError:
            print(f"Erro: Arquivo '{filename}' não encontrado.")
        except Exception as e:
            print(f"Erro: {e}")
    else:
        print("Uso: python vm.py <arquivo.asm>")
        print("\nExemplo:")
        print("  1. Compile: ./airlang programa.air")
        print("  2. Execute: python vm.py programa.asm")