%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern int line_number;

void yyerror(const char* s);
%}

%union {
    int num;
    char* str;
}

%token LIGAR DESLIGAR DEFINIR AJUSTAR MOSTRAR
%token SE ENTAO SENAO ENQUANTO
%token TEMPERATURA VELOCIDADE
%token TEMP_AMBIENTE UMIDADE ENERGIA
%token EQ NEQ GT LT GTE LTE
%token ASSIGN PLUS MINUS TIMES DIVIDE
%token SEMICOLON LBRACE RBRACE LPAREN RPAREN

%token <num> NUMBER
%token <str> STRING IDENTIFICADOR

%type <num> expressao termo fator

%left PLUS MINUS
%left TIMES DIVIDE

%%

programa:
    /* vazio */
    | programa comando
    ;

comando:
    atribuicao
    | ligar_cmd
    | desligar_cmd
    | definir_cmd
    | ajustar_cmd
    | mostrar_cmd
    | se_cmd
    | enquanto_cmd
    ;

atribuicao:
    TEMPERATURA ASSIGN expressao SEMICOLON { 
        printf("✓ Atribuição: temperatura = %d\n", $3); 
    }
    | VELOCIDADE ASSIGN expressao SEMICOLON { 
        printf("✓ Atribuição: velocidade = %d\n", $3); 
    }
    | IDENTIFICADOR ASSIGN expressao SEMICOLON {
        printf("✓ Atribuição: %s = %d\n", $1, $3);
        free($1);
    }
    ;

ligar_cmd:
    LIGAR SEMICOLON { 
        printf("✓ Comando: LIGAR\n"); 
    }
    ;

desligar_cmd:
    DESLIGAR SEMICOLON { 
        printf("✓ Comando: DESLIGAR\n"); 
    }
    ;

definir_cmd:
    DEFINIR TEMPERATURA NUMBER SEMICOLON { 
        printf("✓ Comando: DEFINIR temperatura %d\n", $3); 
    }
    ;

ajustar_cmd:
    AJUSTAR VELOCIDADE NUMBER SEMICOLON { 
        printf("✓ Comando: AJUSTAR velocidade %d\n", $3); 
    }
    ;

mostrar_cmd:
    MOSTRAR STRING SEMICOLON { 
        printf("✓ Comando: MOSTRAR %s\n", $2); 
        free($2);
    }
    | MOSTRAR TEMPERATURA SEMICOLON { 
        printf("✓ Comando: MOSTRAR temperatura\n"); 
    }
    | MOSTRAR VELOCIDADE SEMICOLON { 
        printf("✓ Comando: MOSTRAR velocidade\n"); 
    }
    | MOSTRAR sensor SEMICOLON
    | MOSTRAR IDENTIFICADOR SEMICOLON {
        printf("✓ Comando: MOSTRAR %s\n", $2);
        free($2);
    }
    ;

se_cmd:
    SE condicao ENTAO bloco { 
        printf("✓ Estrutura: SE-ENTAO\n"); 
    }
    | SE condicao ENTAO bloco SENAO bloco { 
        printf("✓ Estrutura: SE-ENTAO-SENAO\n"); 
    }
    ;

enquanto_cmd:
    ENQUANTO condicao bloco { 
        printf("✓ Estrutura: ENQUANTO\n"); 
    }
    ;

bloco:
    LBRACE programa RBRACE
    ;

condicao:
    expressao operador_comparacao expressao
    ;

operador_comparacao:
    EQ | NEQ | GT | LT | GTE | LTE
    ;

expressao:
    termo
    | expressao PLUS termo { $$ = $1 + $3; }
    | expressao MINUS termo { $$ = $1 - $3; }
    ;

termo:
    fator
    | termo TIMES fator { $$ = $1 * $3; }
    | termo DIVIDE fator { 
        if ($3 == 0) {
            yyerror("Divisão por zero");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
    ;

fator:
    NUMBER { $$ = $1; }
    | TEMPERATURA { $$ = 0; }
    | VELOCIDADE { $$ = 0; }
    | IDENTIFICADOR {
        free($1);
        $$ = 0;
    }
    | sensor { $$ = 0; }
    | LPAREN expressao RPAREN { $$ = $2; }
    ;

sensor:
    TEMP_AMBIENTE { printf("  → Sensor: TEMP_AMBIENTE\n"); }
    | UMIDADE { printf("  → Sensor: UMIDADE\n"); }
    | ENERGIA { printf("  → Sensor: ENERGIA\n"); }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "❌ ERRO na linha %d: %s\n", line_number, s);
}

int main(int argc, char** argv) {
    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            perror("Erro ao abrir arquivo");
            return 1;
        }
        yyin = file;
    }
    
    printf("=== AirLang - Analisador Sintático ===\n\n");
    
    int result = yyparse();
    
    printf("\n");
    if (result == 0) {
        printf("✅ SUCESSO! Programa válido.\n");
    } else {
        printf("❌ FALHOU! Existem erros.\n");
    }
    
    return result;
}