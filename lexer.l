/* lexer.l */
%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

int yycolumn = 1;

static void advance_col(void) {
    yycolumn += (int)yyleng;
}
%}

%option noyywrap yylineno

%%

[ \t]+                  { advance_col(); }

\n                      { yycolumn = 1; return '\n'; }

/* números */
[0-9]+                  {
                           yylval.num = atof(yytext);
                           advance_col();
                           return NUMBER;
                        }

/* identificadores */
[a-zA-Z_][a-zA-Z0-9_]*   {
                           yylval.id = strdup(yytext);
                           advance_col();
                           return ID;
                        }

/* operadores y símbolos */
"^"                     { advance_col(); return '^'; }
"="                     { advance_col(); return '='; }
"("                     { advance_col(); return '('; }
")"                     { advance_col(); return ')'; }
"+"                     { advance_col(); return '+'; }
"-"                     { advance_col(); return '-'; }
"*"                     { advance_col(); return '*'; }
"/"                     { advance_col(); return '/'; }

/* carácter inválido */
.                       {
                           fprintf(stderr,
                                   "Error léxico en línea %d, columna %d: carácter inválido '%s'\n",
                                   yylineno, yycolumn, yytext);
                           advance_col();
                        }

%%
