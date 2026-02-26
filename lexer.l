%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
%}

%option noyywrap yylineno

%%

[ \t]+                  ;              /* ignora espacios */
\n                      return '\n';

[0-9]+                  { yylval.num = atof(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]*   { yylval.id = strdup(yytext); return ID; }

"^"                     return '^';
"="                     return '=';
"("                     return '(';
")"                     return ')';
"+"                     return '+';
"-"                     return '-';
"*"                     return '*';
"/"                     return '/';

.                       { printf("Error léxico: '%s'\n", yytext); }

%%
