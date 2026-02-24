/* lexer.l */
%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

/* Para columnas */
int yycolumn = 1;

/* Actualiza columna sumando longitud del lexema */
static void advance_col(void) {
    yycolumn += (int)yyleng;
}

/* Bison locations */
#define YY_USER_ACTION                           \
    yylloc.first_line   = yylineno;              \
    yylloc.last_line    = yylineno;              \
    yylloc.first_column = yycolumn;              \
    yylloc.last_column  = yycolumn + (int)yyleng - 1;
%}

/* Opciones útiles */
%option noyywrap yylineno

%%

[ \t]+                 { advance_col(); /* ignorar espacios */ }

\n                     { yycolumn = 1; return '\n'; }

/* Números */
[0-9]+                 {
                          yylval.num = (double)atof(yytext);
                          advance_col();
                          return NUMBER;
                      }

/* Identificadores (variables) */
[a-zA-Z_][a-zA-Z0-9_]*  {
                          yylval.id = strdup(yytext);
                          advance_col();
                          return ID;
                      }

/* Operadores y paréntesis (se devuelven como char) */
"^"                    { advance_col(); return '^'; }
"="                    { advance_col(); return '='; }
"("                    { advance_col(); return '('; }
")"                    { advance_col(); return ')'; }
"+"                    { advance_col(); return '+'; }
"-"                    { advance_col(); return '-'; }
"*"                    { advance_col(); return '*'; }
"/"                    { advance_col(); return '/'; }

/* Cualquier otro carácter: error léxico y lo consumimos */
.                      {
                          fprintf(stderr, "Error léxico en línea %d, columna %d: carácter inválido '%s'\n",
                                  yylineno, yycolumn, yytext);
                          advance_col();
                      }

%%

/* Con %option noyywrap, ya no hace falta yywrap() */
