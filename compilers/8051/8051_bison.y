%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<math.h>
char lexema[255];
void yyerror(char *);

typedef struct {char nombre[255]; double valor; int token;}tipoTS;
tipoTS TablaSim[100];
int nSim=0;

#define totalFields 6
#define totalCodes 100
typedef struct{int op; int aArray[totalFields]}tipoCodigo;
tipoCodigo TCodigo[totalCodes];
int cx=-1;

int generaCodigo(int, int[], int);
int localizaSimb(char*, int);
void imprimeTablaSim();
int nVarTemp=0;
int GenVarTemp();

int* getElements(int*, int); // Genera arreglo de componentes para ser usados como argumentos
int evalCondition(int);
int evalFlag=1;

void evalLoop(int codeA, int codeB);
void duplicate(int codeA, int codeB);
int loopFlag=0;

char tokenList[15][30];

int iterationIndexA, iterationIndexB;

int evalBuffer[totalFields];
int bufferUsed = 0;
int* append(int, int*, int);
%}

%token REG NUM ENTER STRING COM IF IFELSE WHILE FOR DEF /* - */ TRUEASSIGN ASSIGN SUM RES MUL DIV EVAL EQ NEQ LES MOR LEQ MEQ ITERLIMIT AND OR /* - */ ID

%%
root:	/* empty */
	|	root line;

lines:	line lines
	|	line {$$=$1;};

line:	structure
	|	exp ';' {$$=$1;}
	|	ENTER;

exp:	assign	{$$=$1;}
	|	call	{$$=$1;};

assign:	REG {$$=localizaSimb(lexema, REG);} '=' unitA {int elements[totalFields] = {$2, $4};int i = generaCodigo(ASSIGN, elements,2); evalCodigo(i);$$=i;};

call: ID {$$=localizaSimb(lexema, REG);} '(' args ')' {int *elements = append($2, evalBuffer, bufferUsed);bufferUsed=0;int i = generaCodigo(EVAL, elements,totalFields); $$=evalCodigo(i);};

args:	element COM args {evalBuffer[bufferUsed++]=$1;}
	|	element {evalBuffer[bufferUsed++]=$1;}
	|	call COM args
	|	call
	|	/* empty */{$$=-1;};

element: 	REG {$$=localizaSimb(lexema,REG);}
		|	NUM {$$=localizaSimb(lexema,NUM);}
		|	'-' NUM {char str[255];strcpy(str, "-");strcat(str, lexema);$$=localizaSimb(str, NUM);}
		|	STRING {$$=localizaSimb(lexema,STRING);};

structure:	ifStructure;
		|	ifElseStructure
		|	whileStructure
		|	forStructure
		|	functionStructure;

statement:	comparisons {$$=$1;}
		|	'!' comparisons {$$=!$2;};

unitA:	unitA operatorA unitB {int i=GenVarTemp();int elements[totalFields] = {i, $1, $3};int j=generaCodigo($2, elements,3);evalCodigo(j);$$=i;}
	|	unitB {$$=$1;};

unitB:	unitB operatorB element {int i=GenVarTemp();int elements[totalFields] = {i, $1, $3};int j=generaCodigo($2, elements,3);evalCodigo(j);$$=i;}
	|	unitB operatorB call
	|	element {$$=$1;}
	|	call;

comparison:	unitA compOperator comparison {int i=GenVarTemp();int elements[totalFields] = {i, $1, $3};int j=generaCodigo($2, elements,3);evalCodigo(j);$$=i;}
		|	unitA {$$=$1;};
	
comparisons:	'(' comparisons ')' compOperator '(' comparisons ')' {int i=GenVarTemp();int elements[totalFields] = {i, $2, $6};int j=generaCodigo($4, elements,3);evalCodigo(j);$$=i;}
		|		comparison {$$=$1;};

operatorA:	'+' {$$=SUM;}
		|	'-' {$$=RES;};

operatorB:	'/' {$$=DIV;}
		|	'*' {$$=MUL;};

compOperator:	'=''='	{$$=EQ;}
			|	'!''='	{$$=NEQ;}
			|	'<'		{$$=LES;}
			|	'>'		{$$=MOR;}
			|	'<''='	{$$=LEQ;}
			|	'>''='	{$$=MEQ;}
			|	AND		{$$=AND;}
			|	OR		{$$=OR;};

ifStructure:		IF '(' statement {evalFlag=evalCondition($3);} ')' '{' lines '}' {evalFlag=1;};
ifElseStructure:	IFELSE '(' statement {evalFlag=evalCondition($3);} ')' '{' lines {evalFlag=(evalFlag+1)%2;} '}' '{' lines '}' {evalFlag=1;};
whileStructure:		WHILE '(' {$$=cx+1;} statement {$$=cx;} {evalFlag=evalCondition($4);}')' '{' {evalFlag=0;} lines 
					{
						//printf("#REG%d#", $4);
						int A=$3;
						int B=$5;
						int C=cx; 
						duplicate(A, B);
						evalFlag=1;
						while(evalCondition($4))
						{
							evalLoop(A,C+B-A+1);
						}
					} '}'{evalFlag=1;};

forStructure:		FOR '(' assign ';' {$$=cx+1;} statement {$$=cx;} {evalFlag=0;}';' {$$=cx;} assign {$$=cx;} ')' '{' {evalFlag=0;} lines
					{
						int A1=$5;
						int A2=$7;

						int B1=$10+1; 
						int B2=$12;

						int C1=B2+1;
						int C2=cx;

						duplicate(A1, A2);
						int CX=moveToEnd(B1, B2);
						evalFlag=1;
						while(evalCondition($6))
						{
							evalLoop(A1,CX);
						}
					} '}';

functionStructure: DEF ID {$$=localizaSimb(lexema, ID);} '(' args ')' '{' lines '}';
%%

void yyerror(char *msg){
	printf("error: %s", msg);
}

int GenVarTemp(){
	char t[60];
	sprintf(t, "_T%d", nVarTemp++);
	return localizaSimb(t, REG);
}

int reservedWord(char lexema[])
{
	if(strcasecmp(lexema,"if")==0) return IF;
	if(strcasecmp(lexema,"ifelse")==0) return IFELSE;
	if(strcasecmp(lexema,"while")==0) return WHILE;
	if(strcasecmp(lexema,"for")==0) return FOR;
	if(strcasecmp(lexema,"def")==0) return DEF;
	if((strcasecmp(lexema,"R0")==0)||(strcasecmp(lexema,"r0")==0)) return REG;
	if((strcasecmp(lexema,"R1")==0)||(strcasecmp(lexema,"r1")==0)) return REG;	
	if((strcasecmp(lexema,"R2")==0)||(strcasecmp(lexema,"r2")==0)) return REG;	
	if((strcasecmp(lexema,"R3")==0)||(strcasecmp(lexema,"r3")==0)) return REG;	
	if((strcasecmp(lexema,"R4")==0)||(strcasecmp(lexema,"r4")==0)) return REG;	
	if((strcasecmp(lexema,"R5")==0)||(strcasecmp(lexema,"r5")==0)) return REG;	
	if((strcasecmp(lexema,"R6")==0)||(strcasecmp(lexema,"r6")==0)) return REG;	
	if((strcasecmp(lexema,"R7")==0)||(strcasecmp(lexema,"r7")==0)) return REG;
	return ID;
}

int* append(int a, int* b, int nb){
	int index = 0;
	int i, j;
	int *result = (int*)malloc(sizeof(int)*totalFields);
	for(i = 0; i < totalFields; i++){result[i]=-1;}
	result[index++] = a;
	for(j = 0; (j < nb) && (index < totalFields); j++){
		result[index++] = b[j];
	}
	return result;
}

int getTrueValue(int va, int op, int vb){
	int a = TablaSim[va].valor;
	int b = TablaSim[vb].valor;
	//printf("Evaluando:%s %d %s:", TablaSim[va].nombre, op, TablaSim[vb].nombre);

	if(op==EQ){return (a == b);}
	else if(op==NEQ){return (a != b);}
	else if(op==LES){return (a < b);}
	else if(op==MOR){return (a > b);}
	else if(op==LEQ){return (a <= b);}
	else if(op==MEQ){return (a >= b);}
	else if(op==AND){return (a && b);}
	else if(op==OR){return (a || b);}
}

int* getElements(int* elements, int totalElements){
	int resultElements[totalFields];
	int i;
	for(i = 0; i < totalFields; i++){
		if(i < totalElements){
			resultElements[i] = elements[i];
		} else {
			resultElements[i] = -1;
		}
	}
	return resultElements;
}

int localizaSimb(char *nom, int tok){
	int i;
	for(i = 0; i<nSim; i++){
		if(!strcasecmp(TablaSim[i].nombre, nom))
			return i;
	}
	strcpy(TablaSim[nSim].nombre, nom);
	TablaSim[nSim].token = tok;
	if(tok == REG) TablaSim[nSim].valor=0.0;
	if(tok == NUM) sscanf(nom, "%lf", &TablaSim[nSim].valor);
	nSim++;
	return nSim-1;
}

int generaCodigo(int op, int aArray[], int usefulFields){
	cx++;
	TCodigo[cx].op=op;
	int i;
	for(i = 0; i < totalFields; i++){
		if(i < usefulFields){
			//resultElements[i] = elements[i];
			TCodigo[cx].aArray[i] = aArray[i];
		} else {
			//resultElements[i] = -1;
			TCodigo[cx].aArray[i] = -1;
		}
	}
	return cx;
}

void evalCodigo(int index){
	if (!evalFlag)
		return;

	int operation = TCodigo[index].op;
	int *elementsArr = TCodigo[index].aArray;

	int element1 = elementsArr[0];
	int element2 = elementsArr[1];
	int element3 = elementsArr[2];

	if(operation==TRUEASSIGN){TablaSim[element1].valor = element2;}
	if(operation==ASSIGN){TablaSim[element1].valor = TablaSim[element2].valor;}
	if(operation==SUM){TablaSim[element1].valor = TablaSim[element2].valor + TablaSim[element3].valor;}
	if(operation==RES){TablaSim[element1].valor = TablaSim[element2].valor - TablaSim[element3].valor;}
	if(operation==MUL){TablaSim[element1].valor = TablaSim[element2].valor * TablaSim[element3].valor;}
	if(operation==DIV){TablaSim[element1].valor = TablaSim[element2].valor / TablaSim[element3].valor;}

	if(operation==EQ){TablaSim[element1].valor = TablaSim[element2].valor == TablaSim[element3].valor;}
	if(operation==NEQ){TablaSim[element1].valor = TablaSim[element2].valor != TablaSim[element3].valor;}
	if(operation==LES){TablaSim[element1].valor = TablaSim[element2].valor < TablaSim[element3].valor;}
	if(operation==MOR){TablaSim[element1].valor = TablaSim[element2].valor > TablaSim[element3].valor;}
	if(operation==LEQ){TablaSim[element1].valor = TablaSim[element2].valor <= TablaSim[element3].valor;}
	if(operation==MEQ){TablaSim[element1].valor = TablaSim[element2].valor >= TablaSim[element3].valor;}
	if(operation==AND){TablaSim[element1].valor = TablaSim[element2].valor && TablaSim[element3].valor;}
	if(operation==OR){TablaSim[element1].valor = TablaSim[element2].valor || TablaSim[element3].valor;}
	
	if(operation==EVAL){evalFunction(elementsArr);}
}

void duplicate(int codeA, int codeB){
	for(int i = codeA; i <= codeB; i++){
		int op = TCodigo[i].op;
		int* aArray = TCodigo[i].aArray;
		int usefulFields = 0;
		while(TCodigo[i].aArray[usefulFields] != -1){usefulFields++;}

		generaCodigo(op, aArray, usefulFields);
	}
}

void moveToEnd(int codeA, int codeB){
	int numCodes = codeB - codeA + 1;
	duplicate(codeA, codeB);
	int i;
	for(i = codeB+1; i <= cx; i++){
		TCodigo[i-numCodes] = TCodigo[i];
	}
	cx = cx - numCodes;
	return(cx);
}

void evalLoop(int codeA, int codeB){
	int j;
	//printf("[%d->%d]", codeA, codeB);
	for(j = codeA; j <= codeB; j++){
		evalCodigo(j);
	}
}

int evalCondition(int index){
	if(TablaSim[index].valor){
		return 1;
	} else {
		return 0;
	}
}

int evalFunction(int* fields){
	char* funName = TablaSim[fields[0]].nombre;
	if(strcasecmp(funName, "print")==0){
		for(int i = 1; i < totalFields; i++){
			if((fields[i] < nSim)&&(fields[i] != -1)){
				printf("%lf", TablaSim[fields[i]].valor);
			}
		}
	} else if(strcasecmp(funName, "println")==0){
		for(int i = 1; i < totalFields; i++){
			if((fields[i] < nSim)&&(fields[i] != -1)){
				printf("%lf", TablaSim[fields[i]].valor);
			}
		}
		printf("\n");
	} else if(strcasecmp(funName, "sqrt")==0){
		double result = sqrt(TablaSim[fields[1]].valor);
		
		char milexema[50];
		snprintf(milexema, 50, "%lf", result);
		
		int indice_valor = localizaSimb(milexema, NUM);
		int indice_contenedor = GenVarTemp();
		int elements[totalFields] = {indice_contenedor, indice_valor};
		int j=generaCodigo(ASSIGN, elements,2);
		evalCodigo(j);
		return indice_contenedor;
	}
	return -1;
}

void imprimeTablaSim(){
	int i;
	for(i = 0; i < nSim; i++){
		printf("%d nombre=%-10s\ttok=%d | valor=%lf\n", i, TablaSim[i].nombre, TablaSim[i].token, TablaSim[i].valor);
	}
}

void imprimeTablaCod(){
	int i;
	for(i = 0; i <= cx; i++){
		printf("%d:", i);
		printf("%-20s\t", tokenList[TCodigo[i].op - 268]);
		printf("fields: [");
		int j;
		for(j = 0; j < totalFields; j++){printf("%d, ", TCodigo[i].aArray[j]);}
		printf("]\n");
		//printf("%d a1=%d a2=%d a3=%d\n", TCodigo[i].op, TCodigo[i].a1, TCodigo[i].a2, TCodigo[i].a3);
	}
}

int yylex(){
	char c;
	while(1){
		c = getchar();
		if (isspace(c)) continue;
		if (c == '\t') continue;
		if (c == ',') return COM;
		if (c == '&') return AND;
		if (c == '|') return OR;
		if (c == '\n') return ENTER;
		

		if (isalpha(c)) {
			int i = 0;
			do{
				lexema[i++]=c;
				c=getchar();
			}while(isalnum(c));

			ungetc(c, stdin);
			lexema[i] = 0;
			return reservedWord(lexema);
		}

		if (c == '"') {
			int i = 0;
			int closureQuote = 0;
			int closureQuoteConfirm = 0;
			do{
				if(closureQuote){closureQuoteConfirm = 1;}
				lexema[i++]=c;
				c=getchar();
				if(c == '"'){closureQuote = 1;}
			}while(!closureQuoteConfirm);

			ungetc(c, stdin);
			lexema[i] = 0;
			return STRING;
		}

		if (isdigit(c)){
			int decimalFlag = 0;
			int decimalReaded = 0;
			int i = 0;
			do{
				if (decimalFlag){decimalReaded = 1;}
				lexema[i++]=c;
				c=getchar();
				if( c == '.' || c == 'e' || c == 'E' ){decimalFlag = 1;}
			}while((isdigit(c)) || (( c == '.' || c == 'e' || c == 'E' )&&(!decimalReaded)));

			ungetc(c, stdin);
			lexema[i] = 0;
			return NUM;
		}
		return c;
	}
}

void initTokenStrings(){
	strcpy(tokenList[0], "TRUEASSIGN");
	strcpy(tokenList[1], "ASSIGN");
	strcpy(tokenList[2], "SUM");
	strcpy(tokenList[3], "RES");
	strcpy(tokenList[4], "MUL");
	strcpy(tokenList[5], "DIV");
	strcpy(tokenList[6], "EVAL");
	strcpy(tokenList[7], "EQ");
	strcpy(tokenList[8], "NEQ");
	strcpy(tokenList[9], "LES");
	strcpy(tokenList[10], "MOR");
	strcpy(tokenList[11], "LEQ");
	strcpy(tokenList[12], "MEQ");
	strcpy(tokenList[13], "ITERLIMIT");
	strcpy(tokenList[14], "AND");
	strcpy(tokenList[15], "OR");
}

int main(){
	initTokenStrings();
	int exe = yyparse(); // Ejecucion del compilador
	printf("\n==============================\n"); // Linea divisora de outputs
	if (!exe) printf("cadena valida \n");
	else printf(" cadena invalida");

	printf("Tabla de simbolos\n");
	imprimeTablaSim();
	printf("\nTabla de codigos\n");
	imprimeTablaCod();

	return 0;
}

/*
x = 10;
y = 12;
z = 1;

while((x <20)&(x > 1)){
	y = 1;
	print(y);
	z = 3;
	print(z);
}

ww = 123;

--

x = 1;

while(x < 3){
	x = x+1;
	print(x);
}

--

x = -2;
y = 3*x-1;

print(x, y);
*/


/*
if((strcasecmp(lexema,"R0")==0)||(strcasecmp(lexema,"r0")==0)) return REG;
	if((strcasecmp(lexema,"R1")==0)||(strcasecmp(lexema,"r1")==0)) return REG;	
	if((strcasecmp(lexema,"R2")==0)||(strcasecmp(lexema,"r2")==0)) return REG;	
	if((strcasecmp(lexema,"R3")==0)||(strcasecmp(lexema,"r3")==0)) return REG;	
	if((strcasecmp(lexema,"R4")==0)||(strcasecmp(lexema,"r4")==0)) return REG;	
	if((strcasecmp(lexema,"R5")==0)||(strcasecmp(lexema,"r5")==0)) return REG;	
	if((strcasecmp(lexema,"R6")==0)||(strcasecmp(lexema,"r6")==0)) return REG;	
	if((strcasecmp(lexema,"R7")==0)||(strcasecmp(lexema,"r7")==0)) return REG;	

	return ID;
*/