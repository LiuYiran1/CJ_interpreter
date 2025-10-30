## VARIABLE DEFINITION

variableDeclaration
    : (LET | VAR | CONST) NL* patternsMaybeIrrefutable
        ( (NL* COLON NL* type)? (NL* ASSIGN NL* expression) | (NL* COLON NL* type) )
    ;

patternsMaybeIrrefutable
    : varBindingPattern
    ;

varBindingPattern
    : identifier
    ;

## EXPRESSION

expression
    : assignmentExpression
    ;

assignmentExpression
    : leftValueExpression NL* ASSIGN NL* logicDisjunctionExpression
    | logicDisjunctionExpression
    ;

leftValueExpression
    : leftValueExpressionWithoutWildCard
    ;

leftValueExpressionWithoutWildCard
    : identifier

logicDisjunctionExpression
    : logicConjunctionExpression (NL* OR NL* logicConjunctionExpression)*
    ;

logicConjunctionExpression
    : bitwiseDisjunctionExpression (NL* AND NL* bitwiseDisjunctionExpression)*
    ;

bitwiseDisjunctionExpression
    : bitwiseConjunctionExpression (NL* BITOR NL* bitwiseConjunctionExpression)*
    ;

bitwiseConjunctionExpression
    : equalityComparisonExpression (NL* BITAND NL* equalityComparisonExpression)*
    ;

equalityComparisonExpression
    : comparisonOrTypeExpression (NL* equalityOperator NL* comparisonOrTypeExpression)?
    ;

comparisonOrTypeExpression
    : additiveExpression (NL* comparisonOperator NL* additiveExpression)?
    ;

additiveExpression
    : multiplicativeExpression (NL* additiveOperator NL* multiplicativeExpression)*
    ;

multiplicativeExpression
    : exponentExpression (NL* multiplicativeOperator NL* exponentExpression)*
    ;

exponentExpression
    : prefixUnaryExpression (NL* exponentOperator NL* prefixUnaryExpression)*
    ;

prefixUnaryExpression
    : prefixUnaryOperator* postfixExpression
    ;

postfixExpression
    : atomicExpression
    | postfixExpression callSuffix
    | postfixExpression NL* DOT NL* identifier
    ;

callSuffix
    : LPAREN NL* (valueArgument (NL* COMMA NL* valueArgument)* NL*)? RPAREN
    ;

valueArgument
    : expression
    ;

atomicExpression
    : literalConstant
    | identifier
    | ifExpression
    | loopExpression
    | jumpExpression
    | parenthesizedExpression
    ;

literalConstant
    : IntegerLiteral
    | booleanLiteral
    | stringLiteral
    | unitLiteral
    ;

booleanLiteral
    : TRUE
    | FALSE
    ;

stringLiteral
    : lineStringLiteral
    ;

lineStringContent
    : LineStrText
    ;

lineStringLiteral
    : QUOTE_OPEN (lineStringContent)* QUOTE_CLOSE
    ;

unitLiteral
    : LPAREN NL* RPAREN
    ;

ifExpression
    : IF NL* LPAREN NL* expression NL* RPAREN NL* block
    (NL* ELSE (NL* ifExpression | NL* block))?
    ;

loopExpression
    : whileExpression
    ;


whileExpression
    : WHILE NL* LPAREN NL* expression NL* RPAREN NL* block
    ;

jumpExpression
    : RETURN (NL* expression)?
    | CONTINUE
    | BREAK
    ;

parenthesizedExpression
    : LPAREN NL* expression NL* RPAREN
    ;

block
    : LCURL expressionOrDeclarations RCURL
    ;

expressionOrDeclarations
    : end* (expressionOrDeclaration (end+ expressionOrDeclaration?)*)?
    ;

expressionOrDeclaration
    : expression
    | varOrfuncDeclaration
    ;

varOrfuncDeclaration
    | variableDeclaration
    ;

assignmentOperator
    : ASSIGN
    ;

equalityOperator
    : NOTEQUAL
    | EQUAL
    ;

comparisonOperator
    : LT
    | GT
    | LE
    | GE
    ;

additiveOperator
    : ADD | SUB
    ;

exponentOperator
    : EXP
    ;

multiplicativeOperator
    : MUL
    | DIV
    | MOD
    ;

prefixUnaryOperator
    : SUB
    | NOT
    ;
