# 🌬️ AirConditioningVM

## Objetivo

Este projeto implementa uma **linguagem de programação de alto nível** chamada **AirLang**, criada para controlar uma máquina virtual (VM) que simula um **ar-condicionado**.

O compilador traduz programas escritos em **AirLang** para **Assembly da AirConditioningVM**, que pode ser executado na VM.  
O trabalho foi desenvolvido como parte da **Atividade Prática Supervisionada (APS)** da disciplina de Logíca da Computação.

---

## Componentes da VM

### 🔹 Registradores

- `temperatura` → valor definido do ar-condicionado
- `velocidade` → velocidade do ventilador

### 🔹 Sensores (read-only)

- `TEMP_AMBIENTE` → temperatura ambiente
- `UMIDADE` → nível de umidade do ar
- `ENERGIA` → nível de energia disponível

### 🔹 Instruções Assembly

- `ON` → liga o ar-condicionado
- `OFF` → desliga o ar-condicionado
- `SET_TEMP N` → define temperatura desejada
- `SET_VEL N` → ajusta velocidade
- `MOV T, N` → atribui valor a registrador
- `SHOW X` → imprime registrador, sensor ou string
- `JNZ LABEL` → salto condicional
- `JMP LABEL` → salto incondicional
- `INC reg` → incrementa registrador
- `DEC reg` → decrementa registrador

---

## EBNF da Linguagem (AirLang)

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
mostrar     = "mostrar" ( SENSOR | "temperatura" | "velocidade" | STRING ) ";" ;

se_entao    = "se" condicao "então" bloco [ "senão" bloco ] ;
enquanto    = "enquanto" condicao bloco ;

bloco       = "{" { comando } "}" ;

condicao    = expressao ( ">" | "<" | "==" | ">=" | "<=" ) expressao ;

expressao   = termo { ("+" | "-") termo } ;
termo       = fator { ("*" | "/") fator } ;
fator       = NUMERO | identificador | "(" expressao ")" ;

SENSOR      = "TEMP_AMBIENTE" | "UMIDADE" | "ENERGIA" ;
identificador = letra { letra | dígito } ;

NUMERO      = dígito { dígito } ;
STRING      = '"' { caractere } '"' ;

letra       = "a" | ... | "z" | "A" | ... | "Z" ;
dígito      = "0" | "1" | ... | "9" ;
```
