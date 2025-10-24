%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "airlang.tab.h"

int line_number = 1;
%}

%option noyywrap

%%

[ \t]+              { /* ignora espaços e tabs */ }
\n                  { line_number++; }

"ligar"             { return LIGAR; }
"desligar"          { return DESLIGAR; }
"definir"           { return DEFINIR; }
"ajustar"           { return AJUSTAR; }
"mostrar"           { return MOSTRAR; }
"se"                { return SE; }
"então"|"entao"     { return ENTAO; }
"senão"|"senao"     { return SENAO; }
"enquanto"          { return ENQUANTO; }
"temperatura"       { return TEMPERATURA; }
"velocidade"        { return VELOCIDADE; }

"TEMP_AMBIENTE"     { return TEMP_AMBIENTE; }
"UMIDADE"           { return UMIDADE; }
"ENERGIA"           { return ENERGIA; }

"=="                { return EQ; }
"!="                { return NEQ; }
">="                { return GTE; }
"<="                { return LTE; }
">"                 { return GT; }
"<"                 { return LT; }

"="                 { return ASSIGN; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return TIMES; }
"/"                 { return DIVIDE; }

";"                 { return SEMICOLON; }
"{"                 { return LBRACE; }
"}"                 { return RBRACE; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }

[0-9]+              { 
                      yylval.num = atoi(yytext); 
                      return NUMBER; 
                    }

[a-zA-Z_][a-zA-Z0-9_]*  {
                      yylval.str = strdup(yytext);
                      return IDENTIFICADOR;
                    }

\"[^\"]*\"          { 
                      yylval.str = strdup(yytext); 
                      return STRING; 
                    }

"//".*              { /* comentário de linha */ }

.                   { 
                      printf("ERRO LÉXICO: caractere '%s' inválido na linha %d\n", 
                             yytext, line_number); 
                    }

%%