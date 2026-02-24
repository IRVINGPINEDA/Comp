%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

int yycolumn = 1;

static void adv(void) { yycolumn += (int)yyleng; }
%}

%option noyywrap yylineno

%%

[ \t]+                  { adv(); }
\n                      { yycolumn = 1; return '\n'; }

[0-9]+                  { yylval.num = atof(yytext); adv(); return NUMBER; }

[a-zA-Z_][a-zA-Z0-9_]*   { yylval.id = strdup(yytext); adv(); return ID; }

/* Operadores y símbolos */
\^                      { adv(); return '^'; }
=                       { adv(); return '='; }
\(                      { adv(); return '('; }
\)                      { adv(); return ')'; }
\+                      { adv(); return '+'; }
-                       { adv(); return '-'; }
\*                      { adv(); return '*'; }
/                       { adv(); return '/'; }

/* Cualquier otro carácter */
.                       {
                           fprintf(stderr,
                                   "Error léxico en línea %d, columna %d: carácter inválido '%s'\n",
                                   yylineno, yycolumn, yytext);
                           adv();
                        }

%%
