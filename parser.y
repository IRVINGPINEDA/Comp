/* parser.y */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* Flex */
int yylex(void);
extern int yylineno;
extern int yycolumn;

/* Bison */
void yyerror(YYLTYPE *loc, const char *s);

/* -------- Tabla de símbolos simple -------- */
typedef struct Var {
    char *name;
    double value;
    struct Var *next;
} Var;

static Var *symtab = NULL;

static Var* find_var(const char *name) {
    for (Var *v = symtab; v; v = v->next) {
        if (strcmp(v->name, name) == 0) return v;
    }
    return NULL;
}

static void set_var(const char *name, double value) {
    Var *v = find_var(name);
    if (!v) {
        v = (Var*)malloc(sizeof(Var));
        v->name = strdup(name);
        v->value = value;
        v->next = symtab;
        symtab = v;
    } else {
        v->value = value;
    }
}

static int get_var(const char *name, double *out) {
    Var *v = find_var(name);
    if (!v) return 0;
    *out = v->value;
    return 1;
}
%}

/* Pedir a Bison que incluya ubicaciones (línea/columna) */
%locations
%define parse.error detailed

%union {
    double num;
    char  *id;
}

%token <num> NUMBER
%token <id>  ID

%type  <num> expr term factor power

/* Precedencias (de menor a mayor) */
%left '+' '-'
%left '*' '/'
%right UMINUS
%right '^'   /* potencia: asociativa a la derecha */

%%

input:
      /* vacío */
    | input line
    ;

line:
      '\n'
    | expr '\n'              { printf("Resultado: %g\n", $1); }
    | ID '=' expr '\n'       { set_var($1, $3); printf("%s = %g\n", $1, $3); free($1); }
    | error '\n'             { fprintf(stderr, "Se omitió la línea por error.\n"); yyerrok; }
    ;

/* Suma/resta */
expr:
      expr '+' term          { $$ = $1 + $3; }
    | expr '-' term          { $$ = $1 - $3; }
    | term                   { $$ = $1; }
    ;

/* Multiplicación/división */
term:
      term '*' factor        { $$ = $1 * $3; }
    | term '/' factor        {
                                if ($3 == 0.0) {
                                    yyerror(&@2, "Error: división entre cero");
                                    $$ = 0.0; /* valor por defecto para continuar */
                                } else {
                                    $$ = $1 / $3;
                                }
                              }
    | factor                 { $$ = $1; }
    ;

/* Factor incluye potencia y paréntesis */
factor:
      '-' factor %prec UMINUS { $$ = -$2; }
    | power                   { $$ = $1; }
    ;

/* Potencia (derecha): 2^3^2 = 2^(3^2) */
power:
      '(' expr ')'            { $$ = $2; }
    | NUMBER                  { $$ = $1; }
    | ID                      {
                                double val;
                                if (!get_var($1, &val)) {
                                    char msg[256];
                                    snprintf(msg, sizeof(msg), "Error: variable no definida '%s'", $1);
                                    yyerror(&@1, msg);
                                    $$ = 0.0;
                                } else {
                                    $$ = val;
                                }
                                free($1);
                              }
    | power '^' factor        { $$ = pow($1, $3); }
    ;

%%

int main(void) {
    printf("Calculadora Bison/Flex (Ctrl+D para salir)\n");
    yyparse();
    return 0;
}

/* Error con ubicación */
void yyerror(YYLTYPE *loc, const char *s) {
    /* loc->first_line / loc->first_column vienen de %locations */
    fprintf(stderr, "Error sintáctico en línea %d, columna %d: %s\n",
            loc->first_line, loc->first_column, s);
}
