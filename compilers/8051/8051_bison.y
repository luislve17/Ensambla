%{
#include<stdio.h>
#include<string.h>
char lexema[255];
void yyerror(char *);
%}

%token ID NUM ENTER STRING COM IF ELSE WHILE FOR LESS AND OR DEF REG

%%
root:	/* empty */
	|	root line;

lines:	line lines;
	|	line

line:	structure
	|	exp ';'
	|	ENTER;

exp:	assign
	|	call;

assign:	REG '=' unit;

call: ID '(' args ')';

args:	element COM args
	|	element
	|	call COM args
	|	call
	|	/* empty */;

element: 	REG
		|	NUM
		|	STRING;

structure:	ifStructure;
		|	ifElseStructure
		|	whileStructure
		|	forStructure
		|	functionStructure;

statement:	comparisons
		|	'!' comparisons;

unit:	element operator unit
	|	call operator unit
	|	element
	|	call;

comparison:	unit compOperator comparison
		|	unit;
	
comparisons:	'(' comparisons ')' compOperator '(' comparisons ')'
		|		comparison;

operator:	'+'
		|	'-'
		|	'/'
		|	'*'
		|	'^';

compOperator:	'=''='
			|	'!''='
			|	'<'
			|	'>'
			|	'<''='
			|	'>''='
			|	AND
			|	OR;

ifStructure:		IF '(' statement ')' '{' lines '}';
ifElseStructure:	IF '(' statement ')' '{' lines '}' ELSE '{' lines '}';
whileStructure:		WHILE '(' statement ')' '{' lines '}';
forStructure:		FOR '(' assign ';' statement ';' assign ')' '{' lines '}';

functionStructure: DEF ID '(' args ')' '{' lines '}';
%%

void yyerror(char *msg){
	printf("error: %s", msg);
}

int reservedWord(char lexema[])
{
	if(strcasecmp(lexema,"if")==0) return IF;
	if(strcasecmp(lexema,"else")==0) return ELSE;
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

int main(){
	if(!yyparse()) printf("cadena valida \n");
	else printf(" cadena invalida\n");
	return 0;
}
