# 🌬️ AirLang & AirConditioningVM

## Objetivo

Este projeto implementa uma **linguagem de programação de alto nível** chamada **AirLang**, criada para controlar uma máquina virtual (VM) que simula um **ar-condicionado**.

O compilador traduz programas escritos em **AirLang** para **Assembly da AirConditioningVM**, que pode ser executado na VM.

Trabalho desenvolvido como parte da **Atividade Prática Supervisionada (APS)** da disciplina de Lógica da Computação.

---

## Arquitetura do Projeto

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Código-fonte  │      │    Assembly     │      │    Execução     │
│    (.air)       │ ──▶  │    (.asm)       │ ──▶  │      (VM)       │
│                 │      │                 │      │                 │
│  AirLang        │      │  AirCondioning  │      │  AirConditioning│
│  (alto nível)   │      │  Assembly       │      │  VM (Python)    │
└─────────────────┘      └─────────────────┘      └─────────────────┘
     Flex/Bison              Compilador              ac_vm.py
```

---

## Componentes da VM

### Registradores (read/write)

| Nome   | Descrição                               |
| ------ | --------------------------------------- |
| `TEMP` | Temperatura definida do ar-condicionado |
| `VEL`  | Velocidade do ventilador                |

### Sensores (read-only)

| Nome       | Descrição            | Valor Inicial |
| ---------- | -------------------- | ------------- |
| `TEMP_AMB` | Temperatura ambiente | 28°C          |
| `HUMID`    | Umidade do ar        | 60%           |
| `ENERGY`   | Energia disponível   | 100%          |

### Memória

- **Variáveis**: Criadas dinamicamente pelo usuário
- **Stack**: Pilha para operações PUSH/POP

---

## Instruções Assembly

### Controle do Ar-Condicionado

| Instrução | Descrição                 |
| --------- | ------------------------- |
| `ON`      | Liga o ar-condicionado    |
| `OFF`     | Desliga o ar-condicionado |

### Manipulação de Dados

| Instrução       | Descrição                              |
| --------------- | -------------------------------------- |
| `SET reg n`     | Define registrador com valor constante |
| `MOV reg1 reg2` | Copia valor de reg2 para reg1          |

### Operações Aritméticas

| Instrução       | Descrição            |
| --------------- | -------------------- |
| `ADD reg1 reg2` | reg1 := reg1 + reg2  |
| `SUB reg1 reg2` | reg1 := reg1 - reg2  |
| `MUL reg1 reg2` | reg1 := reg1 \* reg2 |
| `DIV reg1 reg2` | reg1 := reg1 / reg2  |
| `INC reg`       | reg := reg + 1       |
| `DEC reg`       | reg := reg - 1       |

### Controle de Fluxo

| Instrução         | Descrição                           |
| ----------------- | ----------------------------------- |
| `GOTO label`      | Salto incondicional                 |
| `JEQ r1 r2 label` | Salta se r1 == r2                   |
| `JNE r1 r2 label` | Salta se r1 != r2                   |
| `JGT r1 r2 label` | Salta se r1 > r2                    |
| `JLT r1 r2 label` | Salta se r1 < r2                    |
| `JGE r1 r2 label` | Salta se r1 >= r2                   |
| `JLE r1 r2 label` | Salta se r1 <= r2                   |
| `DECJZ reg label` | Se reg == 0 salta, senão decrementa |

### Stack

| Instrução  | Descrição                         |
| ---------- | --------------------------------- |
| `PUSH reg` | Empilha valor do registrador      |
| `POP reg`  | Desempilha valor para registrador |

### I/O e Controle

| Instrução   | Descrição                             |
| ----------- | ------------------------------------- |
| `PRINT arg` | Imprime registrador, sensor ou string |
| `HALT`      | Encerra execução                      |

---

## EBNF da Linguagem AirLang

```ebnf
programa    = { comando } ;

comando     = atribuicao
            | ligar
            | desligar
            | definir
            | ajustar
            | mostrar
            | se_entao
            | enquanto ;

atribuicao  = ( "temperatura" | "velocidade" | identificador ) "=" expressao ";" ;

ligar       = "ligar" ";" ;
desligar    = "desligar" ";" ;
definir     = "definir" "temperatura" NUMERO ";" ;
ajustar     = "ajustar" "velocidade" NUMERO ";" ;
mostrar     = "mostrar" ( SENSOR | "temperatura" | "velocidade" | STRING | identificador ) ";" ;

se_entao    = "se" condicao "entao" bloco [ "senao" bloco ] ;
enquanto    = "enquanto" condicao bloco ;

bloco       = "{" { comando } "}" ;

condicao    = expressao ( ">" | "<" | "==" | "!=" | ">=" | "<=" ) expressao ;

expressao   = termo { ("+" | "-") termo } ;
termo       = fator { ("*" | "/") fator } ;
fator       = NUMERO | "temperatura" | "velocidade" | SENSOR | identificador | "(" expressao ")" ;

SENSOR      = "TEMP_AMBIENTE" | "UMIDADE" | "ENERGIA" ;
identificador = letra { letra | digito | "_" } ;
NUMERO      = digito { digito } ;
STRING      = '"' { caractere } '"' ;
```

---
