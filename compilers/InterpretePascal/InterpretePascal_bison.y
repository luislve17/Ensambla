%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
char lexema[60];
void yyerror(char *msg);
typedef struct {char nombre[60]; double valor; int token;}tipoTS;
tipoTS TablaSim[100];
int nSim=0;
typedef struct{int op; int a1; int a2; int a3;}tipoCodigo;
int cx=-1;
tipoCodigo TCodigo[100];
void generaCodigo(int, int, int, int);
int localizaSimb(char*, int);
void imprimeTablaSim();
int nVarTemp=0;
int GenVarTemp();
%}

%token PROGRAMA ID INICIO FIN NUM VARIABLE ASIGNAR SUMAR

%%

S: PROGRAMA ID ';' listadeclaracion INICIO ListaInstr FIN '.';

listadeclaracion: /* vacio */;

ListaInstr: instr ListaInstr
			| /* vacio */	;

instr: ID {$$=localizaSimb(lexema, ID);}':''='expr {generaCodigo(ASIGNAR, $2, $5, '-');}';';

expr:	expr '+' term {int i=GenVarTemp();generaCodigo(SUMAR, i, $1, $3);$$=i;}
	|	expr '-' term
	|	term;

term:	term '*' fact
	|	term '/' fact
	|	fact;

fact:	NUM {$$=localizaSimb(lexema,NUM);}
	|	ID{$$=localizaSimb(lexema,ID);};

%%

int GenVarTemp(){
	char t[60];
	sprintf(t, "_T%d", nVarTemp++);
	return localizaSimb(t, ID);
}

void generaCodigo(int op, int a1, int a2, int a3){
	cx++;
	TCodigo[cx].op=op;
	TCodigo[cx].a1=a1;
	TCodigo[cx].a2=a2;
	TCodigo[cx].a3=a3;
}

int localizaSimb(char *nom, int tok){
	int i;
	for(i = 0; i<nSim; i++){
		if(!strcasecmp(TablaSim[i].nombre, nom))
			return i;
	}
	strcpy(TablaSim[nSim].nombre, nom);
	TablaSim[nSim].token = tok;
	if(tok == ID) TablaSim[nSim].valor=0.0;
	if(tok == NUM) sscanf(nom, "%lf", &TablaSim[nSim].valor);
	nSim++;
	return nSim-1;
}

void imprimeTablaSim(){
	int i;
	for(i = 0; i < nSim; i++){
		printf("%d nombre=%s tok=%d valor=%lf\n", i, TablaSim[i].nombre, TablaSim[i].token, TablaSim[i].valor);
	}
}

void imprimeTablaCod(){
	int i;
	for(i = 0; i <= cx; i++){
		printf("%d a1=%d a2=%d a3=%d\n", TCodigo[i].op, TCodigo[i].a1, TCodigo[i].a2, TCodigo[i].a3);
	}
}

void yyerror(char *mgs){
    printf("error:%s",mgs);
}

int EsPalabraReservada(char lexema[]){
	if (strcasecmp(lexema, "Program")==0) return PROGRAMA;
	if (strcasecmp(lexema, "Begin")==0) return INICIO;
	if (strcasecmp(lexema, "End")==0) return FIN;
	return ID;
}

int yylex(){
	char c;
	while(1){
		c = getchar();
		if (c == ' ') continue;
		if (c == '\t') continue;
		if (c == '\n') continue;

		if (isalpha(c)) {
			int i = 0;
			do{
				lexema[i++]=c;
				c=getchar();
			}while(isalnum(c));

			ungetc(c, stdin);
			lexema[i] = '\0';
			return EsPalabraReservada(lexema);
		}

		if (isdigit(c)){
			//int decimalFlag = 0;
			//int decimalReaded = 0;
			int i = 0;
			do{
				//if (decimalFlag){decimalReaded = 1;}
				lexema[i++]=c;
				c=getchar();
				//if( c == '.' || c == 'e' || c == 'E' ){decimalFlag = 1;}
			}while((isdigit(c)));// || (( c == '.' || c == 'e' || c == 'E' )&&(!decimalReaded)));

			ungetc(c, stdin);
			lexema[i] = '\0';
			return NUM;
		}
		return c;
	}
}

int main(){
	if (!yyparse()) printf("La cadena es valida\n");
	else printf("La cadena es invalida");

	printf("Tabla de simbolos\n");
	imprimeTablaSim();
	printf("\nTabla de codigos\n");
	imprimeTablaCod();
}