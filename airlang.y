%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern int line_number;

void yyerror(const char* s);

FILE* output_file = NULL;
int label_counter = 0;
int temp_counter = 0;

#define MAX_LABEL_STACK 100
int label_stack[MAX_LABEL_STACK];
int label_stack_top = 0;

char cond_left[256], cond_right[256];
char cond_op[4];

void emit(const char* fmt, ...);
int new_label(void);
void push_label(int label);
int pop_label(void);
void emit_condicao_invertida(int label);
void init_codegen(const char* filename);
void finish_codegen(void);
char* new_temp(void);

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

%type <str> expressao termo fator sensor

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
        emit("MOV TEMP %s", $3);
        free($3);
    }
    | VELOCIDADE ASSIGN expressao SEMICOLON { 
        emit("MOV VEL %s", $3);
        free($3);
    }
    | IDENTIFICADOR ASSIGN expressao SEMICOLON {
        emit("MOV %s %s", $1, $3);
        free($1);
        free($3);
    }
    ;

ligar_cmd:
    LIGAR SEMICOLON { 
        emit("ON");
    }
    ;

desligar_cmd:
    DESLIGAR SEMICOLON { 
        emit("OFF");
    }
    ;

definir_cmd:
    DEFINIR TEMPERATURA NUMBER SEMICOLON { 
        emit("SET TEMP %d", $3);
    }
    ;

ajustar_cmd:
    AJUSTAR VELOCIDADE NUMBER SEMICOLON { 
        emit("SET VEL %d", $3);
    }
    ;

mostrar_cmd:
    MOSTRAR STRING SEMICOLON { 
        emit("PRINT %s", $2);
        free($2);
    }
    | MOSTRAR TEMPERATURA SEMICOLON { 
        emit("PRINT TEMP");
    }
    | MOSTRAR VELOCIDADE SEMICOLON { 
        emit("PRINT VEL");
    }
    | MOSTRAR sensor SEMICOLON {
        emit("PRINT %s", $2);
        free($2);
    }
    | MOSTRAR IDENTIFICADOR SEMICOLON {
        emit("PRINT %s", $2);
        free($2);
    }
    ;

condicao:
    expressao GT expressao  { strcpy(cond_left, $1); strcpy(cond_right, $3); strcpy(cond_op, ">"); free($1); free($3); }
    | expressao LT expressao  { strcpy(cond_left, $1); strcpy(cond_right, $3); strcpy(cond_op, "<"); free($1); free($3); }
    | expressao EQ expressao  { strcpy(cond_left, $1); strcpy(cond_right, $3); strcpy(cond_op, "=="); free($1); free($3); }
    | expressao NEQ expressao { strcpy(cond_left, $1); strcpy(cond_right, $3); strcpy(cond_op, "!="); free($1); free($3); }
    | expressao GTE expressao { strcpy(cond_left, $1); strcpy(cond_right, $3); strcpy(cond_op, ">="); free($1); free($3); }
    | expressao LTE expressao { strcpy(cond_left, $1); strcpy(cond_right, $3); strcpy(cond_op, "<="); free($1); free($3); }
    ;

se_inicio:
    SE condicao ENTAO {
        int lbl = new_label();
        push_label(lbl);
        emit("MOV _cmp1 %s", cond_left);
        emit("MOV _cmp2 %s", cond_right);
        emit_condicao_invertida(lbl);
    }
    ;

se_cmd:
    se_inicio bloco { 
        int lbl = pop_label();
        emit("L%d:", lbl);
    }
    | se_inicio bloco SENAO {
        int lbl_else = pop_label();
        int lbl_end = new_label();
        push_label(lbl_end);
        emit("GOTO L%d", lbl_end);
        emit("L%d:", lbl_else);
    } bloco {
        int lbl_end = pop_label();
        emit("L%d:", lbl_end);
    }
    ;

enquanto_inicio:
    ENQUANTO {
        int lbl_start = new_label();
        push_label(lbl_start);
        emit("L%d:", lbl_start);
    } condicao {
        int lbl_end = new_label();
        push_label(lbl_end);
        emit("MOV _cmp1 %s", cond_left);
        emit("MOV _cmp2 %s", cond_right);
        emit_condicao_invertida(lbl_end);
    }
    ;

enquanto_cmd:
    enquanto_inicio bloco { 
        int lbl_end = pop_label();
        int lbl_start = pop_label();
        emit("GOTO L%d", lbl_start);
        emit("L%d:", lbl_end);
    }
    ;

bloco:
    LBRACE programa RBRACE
    ;

sensor:
    TEMP_AMBIENTE { $$ = strdup("TEMP_AMB"); }
    | UMIDADE { $$ = strdup("HUMID"); }
    | ENERGIA { $$ = strdup("ENERGY"); }
    ;

expressao:
    termo { $$ = $1; }
    | expressao PLUS termo { 
        char* tmp = new_temp();
        emit("MOV %s %s", tmp, $1);
        emit("ADD %s %s", tmp, $3);
        free($1);
        free($3);
        $$ = tmp;
    }
    | expressao MINUS termo { 
        char* tmp = new_temp();
        emit("MOV %s %s", tmp, $1);
        emit("SUB %s %s", tmp, $3);
        free($1);
        free($3);
        $$ = tmp;
    }
    ;

termo:
    fator { $$ = $1; }
    | termo TIMES fator { 
        char* tmp = new_temp();
        emit("MOV %s %s", tmp, $1);
        emit("MUL %s %s", tmp, $3);
        free($1);
        free($3);
        $$ = tmp;
    }
    | termo DIVIDE fator { 
        char* tmp = new_temp();
        emit("MOV %s %s", tmp, $1);
        emit("DIV %s %s", tmp, $3);
        free($1);
        free($3);
        $$ = tmp;
    }
    ;

fator:
    NUMBER { 
        char buf[32];
        sprintf(buf, "%d", $1);
        $$ = strdup(buf);
    }
    | TEMPERATURA { 
        $$ = strdup("TEMP");
    }
    | VELOCIDADE { 
        $$ = strdup("VEL");
    }
    | IDENTIFICADOR {
        $$ = $1;
    }
    | sensor {
        $$ = $1;
    }
    | LPAREN expressao RPAREN { 
        $$ = $2; 
    }
    ;

%%

void emit(const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    if (output_file) {
        vfprintf(output_file, fmt, args);
        fprintf(output_file, "\n");
    }
    va_end(args);
    
    va_start(args, fmt);
    printf("  ");
    vprintf(fmt, args);
    printf("\n");
    va_end(args);
}

int new_label(void) {
    return label_counter++;
}

char* new_temp(void) {
    char buf[32];
    sprintf(buf, "_t%d", temp_counter++);
    return strdup(buf);
}

void push_label(int label) {
    if (label_stack_top < MAX_LABEL_STACK) {
        label_stack[label_stack_top++] = label;
    }
}

int pop_label(void) {
    if (label_stack_top > 0) {
        return label_stack[--label_stack_top];
    }
    return 0;
}

void emit_condicao_invertida(int label) {
    if (strcmp(cond_op, ">") == 0) {
        emit("JLE _cmp1 _cmp2 L%d", label);
    } else if (strcmp(cond_op, "<") == 0) {
        emit("JGE _cmp1 _cmp2 L%d", label);
    } else if (strcmp(cond_op, "==") == 0) {
        emit("JNE _cmp1 _cmp2 L%d", label);
    } else if (strcmp(cond_op, "!=") == 0) {
        emit("JEQ _cmp1 _cmp2 L%d", label);
    } else if (strcmp(cond_op, ">=") == 0) {
        emit("JLT _cmp1 _cmp2 L%d", label);
    } else if (strcmp(cond_op, "<=") == 0) {
        emit("JGT _cmp1 _cmp2 L%d", label);
    }
}

void init_codegen(const char* filename) {
    output_file = fopen(filename, "w");
    if (!output_file) {
        perror("Erro ao criar arquivo de saida");
        exit(1);
    }
    fprintf(output_file, "; === AirConditioningVM Assembly ===\n");
    fprintf(output_file, "; Gerado pelo compilador AirLang\n\n");
}

void finish_codegen(void) {
    if (output_file) {
        fprintf(output_file, "HALT\n");
        fclose(output_file);
    }
}

void yyerror(const char* s) {
    fprintf(stderr, "ERRO na linha %d: %s\n", line_number, s);
}

int main(int argc, char** argv) {
    char output_filename[256] = "output.asm";
    
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo.air> [arquivo.asm]\n", argv[0]);
        return 1;
    }
    
    FILE* file = fopen(argv[1], "r");
    if (!file) {
        perror("Erro ao abrir arquivo");
        return 1;
    }
    yyin = file;
    
    if (argc > 2) {
        strncpy(output_filename, argv[2], sizeof(output_filename) - 1);
    } else {
        char* dot = strrchr(argv[1], '.');
        if (dot) {
            int len = dot - argv[1];
            strncpy(output_filename, argv[1], len);
            output_filename[len] = '\0';
            strcat(output_filename, ".asm");
        } else {
            snprintf(output_filename, sizeof(output_filename), "%s.asm", argv[1]);
        }
    }
    
    printf("=== AirLang Compiler ===\n");
    printf("Entrada: %s\n", argv[1]);
    printf("Saida:   %s\n\n", output_filename);
    
    init_codegen(output_filename);
    int result = yyparse();
    finish_codegen();
    fclose(file);
    
    if (result == 0) {
        printf("\nCompilacao bem-sucedida!\n");
    } else {
        printf("\nCompilacao falhou!\n");
    }
    
    return result;
}