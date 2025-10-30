# CURRENT GRAMMAR

## Notes

Look at [Symbols](https://docs.cangjie-lang.cn/en/docs/0.53.13/spec/source_en/Chapter_Appendix_A.html?highlight=syntax#symbols) if you need it.

## TRANSLATION UNIT

    translationUnit
        : end* (topLevelObject (end+ topLevelObject?)*)? 
        (end+ mainDefinition)? NL* (topLevelObject (end+ topLevelObject?)*)? EOF
        ;

    end
        : NL | SEMI
        ;

--------------------------------------------------------------------------------

## TOP-LEVEL DEFINITION

    topLevelObject
    : functionDefinition
    | classDefintion
    | variableDeclaration
    | interfaceDefinition
    ;

--------------------------------------------------------------------------------

## CLASS DEFINITION

    classDefinition
        : CLASS NL* identifier
        (NL* UPPERBOUND NL* superClassOrInterfaces)?
        NL* classBody
        ;

    superClassOrInterfaces
        : superClass (NL* BITAND NL* superInterfaces)?
        | superInterfaces
        ;

    superClass
        : classType
        ;

    classType
        : (identifier NL* DOT  NL*)*  identifier
        ;

    superInterfaces
        : interfaceType (NL* BITAND NL* interfaceType )*
        ;

    interfaceType
        : classType
        ;

    upperBounds
        : type (NL* BITAND NL* type)*
        ;

    classBody
        : LCURL  end* (classMemberDeclaration (end+ classMemberDeclaration?)*)?
            end* RCURL
        ;

    classMemberDeclaration
        : (classInit
        | variableDeclaration
        | functionDefinition
        )? end*
        ;

    classInit
        : INIT NL* functionParameters NL* block
        ;

    className
        : identifier
        ;

--------------------------------------------------------------------------------

## INTERFACE DEFINITION

    interfaceDefinition
        : INTERFACE NL* identifier
        (NL* UPPERBOUND NL* superInterfaces)?
        (NL* interfaceBody)
        ;

    interfaceBody
        : LCURL end* interfaceMemberDeclaration* end* RCURL
        ;

    interfaceMemberDeclaration
        : (functionDefinition) end*
        ;

--------------------------------------------------------------------------------

## FUNCTION DEFINITION

    functionDefinition
        :FUNC
         NL* identifier
         NL* functionParameters
        (NL* COLON NL* type)?
        (NL* block)?
        ;

    functionParameters
        : (LPAREN (NL* unnamedParameterList)? 
            NL* RPAREN NL*)
        ;

    unnamedParameterList
        : unnamedParameter (NL* COMMA NL*  unnamedParameter)*
        ;

    unnamedParameter
        : (identifier | WILDCARD) NL* COLON NL* type
        ;

--------------------------------------------------------------------------------

## VARIABLE DEFINITION

    variableDeclaration
        : (LET | VAR | CONST) NL* patternsMaybeIrrefutable
            ( (NL* COLON NL* type)? (NL* ASSIGN NL* expression) | (NL* COLON NL* type) )
        ;
--------------------------------------------------------------------------------

## MAIN ENTRY DEFINITION

    mainDefinition
        : MAIN
        NL* functionParameters
        (NL* COLON NL* type)?
        NL* block
        ;
--------------------------------------------------------------------------------

## TYPE

    // Recheck when need to add Option.
    type
        : atomicType
        ;

    atomicType
        : charLangTypes
        ;

    charLangTypes
        : numericTypes
        | RUNE
        | BOOLEAN
        | Nothing
        | UNIT
        | THISTYPE
        ;

    numericTypes
        : INT8
        | INT16
        | INT32
        | INT64
        | INTNATIVE
        | UINT8
        | UINT16
        | UINT32
        | UINT64
        | UINTNATIVE
        | FLOAT16
        | FLOAT32
        | FLOAT64
        ;

--------------------------------------------------------------------------------

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
        | leftAuxExpression NL* assignableSuffix
        ;

    leftAuxExpression
        : identifier
        | type
        | thisSuperExpression
        | leftAuxExpression fieldAccess
        | leftAuxExpression callSuffix
        ;

    assignableSuffix
        : fieldAccess
        ;

    fieldAccess
        : NL* DOT NL* identifier
        ;

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
        | type NL* DOT NL* identifier
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
        | unitLiteral <!-- It's already in literal constant lol -->
        | ifExpression
        | loopExpression
        | jumpExpression
        | thisSuperExpression
        | parenthesizedExpression
        ;

    literalConstant
        : IntegerLiteral
        | FloatLiteral
        | RuneLiteral
        | ByteLiteral <!-- Does this even exist? -->
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
        :  LineStrText
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

    deconstructPattern
        : wildcardPattern
        | varBindingPattern
        ;

    pattern
    : wildcardPattern
    | varBindingPattern
    | typePattern
    ;

    varBindingPattern
    : identifier
    ;

    typePattern
    : (WILDCARD | identifier) NL* COLON NL* type
    ;

    loopExpression
        : whileExpression
        ;

    patternsMaybeIrrefutable
        : wildcardPattern
        | varBindingPattern
        ;

    whileExpression
        : WHILE NL* LPAREN NL* expression NL* RPAREN NL* block
        ;
    
    jumpExpression
        : RETURN (NL* expression)?
        | CONTINUE
        | BREAK
        ;

    thisSuperExpression
        : THIS
        | SUPER
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
        : functionDefinition
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
