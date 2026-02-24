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
int yyerror(const char *s);

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

%union {
    double num;
    char  *id;
}

%token <num> NUMBER
%token <id>  ID

%type  <num> expr term pow unary primary

%left '+' '-'
%left '*' '/'
%right '^'
%right UMINUS

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

expr:
      expr '+' term          { $$ = $1 + $3; }
    | expr '-' term          { $$ = $1 - $3; }
    | term                   { $$ = $1; }
    ;

term:
      term '*' pow           { $$ = $1 * $3; }
    | term '/' pow           {
                                if ($3 == 0.0) {
                                    yyerror("Error: división entre cero");
                                    $$ = 0.0;
                                } else {
                                    $$ = $1 / $3;
                                }
                              }
    | pow                    { $$ = $1; }
    ;

/* Potencia a la derecha: a^b^c = a^(b^c) */
pow:
      unary                  { $$ = $1; }
    | unary '^' pow          { $$ = pow($1, $3); }
    ;

unary:
      '-' unary %prec UMINUS { $$ = -$2; }
    | primary                { $$ = $1; }
    ;

primary:
      '(' expr ')'           { $$ = $2; }
    | NUMBER                 { $$ = $1; }
    | ID                     {
                                double val;
                                if (!get_var($1, &val)) {
                                    fprintf(stderr,
                                            "Error en línea %d, columna %d: variable no definida '%s'\n",
                                            yylineno, yycolumn, $1);
                                    $$ = 0.0;
                                } else {
                                    $$ = val;
                                }
                                free($1);
                              }
    ;

%%

int main(void) {
    printf("Calculadora Bison/Flex (Ctrl+D para salir)\n");
    yyparse();
    return 0;
}

int yyerror(const char *s) {
    fprintf(stderr, "Error en línea %d, columna %d: %s\n", yylineno, yycolumn, s);
    return 0;
}
