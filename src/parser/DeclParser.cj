package cjcj.parser

import cjcj.visitor.*
import cjcj.scanner.Token
import cjcj.scanner.TokenKind
import cjcj.scanner.TokenKindHelper
import std.collection.ArrayList
import std.ast.Position

private type TK = TokenKind

private type TKH = TokenKindHelper

internal open class DeclParser {
    private static const MAX_PARAM_NUMBER = 255

    public DeclParser(private let helper: ParserHelper, private let reporter: Reporter) {
    }

    func topLevelObject(): ?Decl {
        if (let Some(funcDef) <- functionDefinition()) {
            return funcDef
        }
        if (let Some(varDecl) <- variableDeclaration()) {
            return varDecl
        }
        if (let Some(classDecl) <- classDefinition()) {
            return classDecl
        }
        if (let Some(interfaceDecl) <- interfaceDefinition()) {
            return interfaceDecl
        }
        None
    }

    private func declaration(): ?Decl {
        helper.skipNL()
        try {
            if (let Some(varDecl) <- variableDeclaration()) {
                return varDecl
            }
            if (let Some(funcDef) <- functionDefinition()) {
                return funcDef
            }
        } catch (error: ParseError) {
            helper.synchronize()
        }
        None
    }

    private func unnamedParameterList(): ArrayList<FuncParam> {
        let parameters: ArrayList<FuncParam> = ArrayList()
        let start: (Token, Int64) = (helper.previous(), helper.current - 1)
        if (helper.check(TK.IDENTIFIER)) {
            do {
                if (helper.check(TK.IDENTIFIER)) {
                    helper.skipNL()
                    if (parameters.size >= MAX_PARAM_NUMBER) {
                        throw helper.error(helper.previous(),
                            "Can't have more than " + MAX_PARAM_NUMBER.toString() + " parameters.", helper.current)
                    }
                    try {
                        parameters.add(unnamedParameter())
                    } catch (e: FinalError) {
                        helper.synchronizeBlockParenthesis(start[0], start[1])
                    }
                } else {
                    helper.error(helper.previous(), "Expected parameter name after comma", helper.current - 1)
                }
                helper.skipNL()
            } while (helper.matches(TK.COMMA))
        }
        return parameters
    }

    private func functionDefinition(): ?FuncDecl {
        if (!helper.matches(TK.FUNC)) {
            return None
        }
        let keyword: Token = helper.previous()
        helper.skipNL()
        let name: Token = helper.consume(TK.IDENTIFIER, "Expect function name.", helper.current)
        var parameters: ArrayList<FuncParam> = ArrayList()
        helper.skipNL()
        parameters = functionParameters()

        var declType: ?TypeNode = None
        helper.skipNL()
        if (helper.matches(TK.COLON)) {
            helper.skipNL()
            declType = nodeType(NodeIdManager.nextId(), name)
        }
        helper.skipNL()

        // Sometimes functions might not have a block, e.g. in an interface, or an abstract class 
        var block_: ?Block = None
        try {
            block_ = block()
        } catch (e: ConsumeError) {
            if (e.message != "No Block") {
                throw e
            } else {
                reporter.pop()
                helper.retreat()
            }
        }

        if (let Some(dtype) <- declType && dtype.typeName.value == "Unit" && let Some(realBlock) <- block_) {
            realBlock
                .nodes
                .add(
                    ReturnExpr(NodeIdManager.nextId(),
                        LitConstExpr(NodeIdManager.nextId(), Token(TK.UNIT_LITERAL, "()", Position())),
                        Token(TK.RETURN, "return", Position())))
        }

        FuncDecl(NodeIdManager.nextId(), keyword, name, block_, parameters, declType)
    }

    private func functionParameters(): ArrayList<FuncParam> {
        if (helper.matches(TK.UNIT_LITERAL)) {
            return ArrayList()
        }
        helper.consume(TK.LPAREN, "Expect '(' before function parameters", helper.current)
        let start: (Token, Int64) = (helper.previous(), helper.current - 1)
        helper.skipNL()
        let parameters: ArrayList<FuncParam> = ArrayList()
        try {
            parameters.add(all: unnamedParameterList())
            helper.skipNL()
            helper.consume(TK.RPAREN, "Expect ')' after function parameters", helper.current)
            helper.skipNL()
        } catch (e: ConsumeError) {
            if (helper.check(TK.LCURL)) {
                reporter.pop()
                reporter.unclosedDelimiterError(helper.peek(), start[0], start[1], helper.current)
            } else {
                helper.synchronizeBlockParenthesis(start[0], start[1])
            }
        } catch (e: ParseError) {
            helper.synchronizeBlockParenthesis(start[0], start[1])
        }
        parameters
    }

    private func classDefinition(): ?ClassDecl {
        if (!helper.matches(TK.CLASS)) {
            return None
        }
        let keyword: Token = helper.previous()
        helper.skipNL()
        let identifier: Token = className()
        helper.skipNL()
        let supertypes: ArrayList<TypeNode> = if (helper.matches(TK.UPPERBOUND)) {
            helper.skipNL()
            superClassOrInterfaces()
        } else {
            ArrayList()
        }
        helper.skipNL()
        try {
            let body: Body = classBody()
            return ClassDecl(NodeIdManager.nextId(), keyword, identifier, body, supertypes)
        } catch (e: ConsumeError) {
            helper.pop()
            helper.error(helper.peek(), "body of class '\u{001b}[31m${identifier}\u{001b}[0m' is missing",
                helper.current)
            return None
        }
    }

    private func className(): Token {
        return helper.consume(TK.IDENTIFIER, "Expect class name.", helper.current)
    }

    private func classBody(): Body {
        let start: (Token, Int64) = (helper.peek(), helper.current)
        helper.consume(TK.LCURL, "Expect '{' before body.", helper.current)
        helper.endStar()
        let decls: ArrayList<Decl> = ArrayList()
        if (let Some(cmd) <- classMemberDeclaration()) {
            decls.add(cmd)

            while (let Some(cmd) <- helper.tryParse(
                    {
                        =>
                            helper.endPlus("", helper.peek(), helper.current);
                            classMemberDeclaration()
                    }
                )) {
                decls.add(cmd)
            }
        }
        helper.endStar()
        try {
            helper.consume(TK.RCURL, "Expect '}' after block.", helper.current)
        } catch (e: ConsumeError) {
            helper.synchronizeBlockRightCurl(start[0], start[1])
            reporter.unclosedDelimiterError(helper.peek(), start[0], start[1], helper.current)
        }
        Body(NodeIdManager.nextId(), decls)
    }

    public func classMemberDeclaration(): ?Decl {
        var decl: ?Decl = None
        if (let Some(classInit) <- classInit()) {
            decl = classInit
        }
        if (let Some(variableDeclaration) <- variableDeclaration()) {
            decl = variableDeclaration
        }
        if (let Some(functionDefinition) <- functionDefinition()) {
            decl = functionDefinition
        }
        decl
    }

    public func classInit(): ?FuncDecl {
        //TODO: look and understand what the const modifier does.
        if (!helper.matches(TK.INIT)) {
            return None
        }
        let keyword: Token = helper.previous()
        let params: ArrayList<FuncParam> = functionParameters()
        helper.skipNL()
        let block: Block = block()
        FuncDecl(NodeIdManager.nextId(), keyword, block, params)
    }

    private func superClassOrInterfaces(): ArrayList<TypeNode> {
        let superClassOrInterfaces: ArrayList<TypeNode> = ArrayList()
        // We assume that the first element of the super classes or interfaces is a class, we will
        // check it in the following process.
        superClassOrInterfaces.add(superClass())
        while (let Some(superClassOrInterface) <- helper.tryParse(
                {
                    =>
                        helper.skipNL()
                        if (helper.matches(TK.BITAND)) {
                            helper.skipNL()
                            return superClass()
                        }
                        None
                }
            )) {
            superClassOrInterfaces.add(superClassOrInterface)
        }
        superClassOrInterfaces
    }

    private func interfaceName(): Token {
        return helper.consume(TK.IDENTIFIER, "Expect interface name.", helper.current)
    }

    private func interfaceDefinition(): ?InterfaceDecl {
        if (!helper.matches(TK.INTERFACE)) {
            return None
        }
        let keyword: Token = helper.previous()
        helper.skipNL()
        let identifier: Token = interfaceName()
        helper.skipNL()
        let supertypes: ArrayList<TypeNode> = if (helper.matches(TK.UPPERBOUND)) {
            helper.skipNL()
            superClassOrInterfaces()
        } else {
            ArrayList()
        }
        helper.skipNL()

        try {
            let body: Body = interfaceBody()
            return InterfaceDecl(NodeIdManager.nextId(), keyword, identifier, body, supertypes)
        } catch (e: ConsumeError) {
            helper.pop()
            helper.error(helper.peek(), "body of interface '\u{001b}[31m${identifier}\u{001b}[0m' is missing",
                helper.current)
            return None
        }
    }

    private func interfaceBody(): Body {
        let start: (Token, Int64) = (helper.peek(), helper.current)
        helper.consume(TK.LCURL, "Expect '{' before body.", helper.current)
        helper.endStar()
        let decls: ArrayList<Decl> = ArrayList()
        if (let Some(cmd) <- interfaceMemberDeclaration()) {
            decls.add(cmd)

            while (let Some(cmd) <- helper.tryParse(
                    {
                        =>
                            helper.endPlus("", helper.peek(), helper.current);
                            interfaceMemberDeclaration()
                    }
                )) {
                decls.add(cmd)
            }
        }
        helper.endStar()

        try {
            helper.consume(TK.RCURL, "Expect '}' after block.", helper.current)
        } catch (e: ConsumeError) {
            helper.synchronizeBlockRightCurl(start[0], start[1])
            reporter.unclosedDelimiterError(helper.peek(), start[0], start[1], helper.current)
        }

        println("Error is found in body : ${reporter.empty}")

        Body(NodeIdManager.nextId(), decls)
    }

    private func interfaceMemberDeclaration(): ?Decl {
        if (let Some(functionDefinition) <- functionDefinition()) {
            functionDefinition
        } else {
            None
        }
    }

    private func superClass(): TypeNode {
        classType()
    }

    private func classType(): TypeNode {
        // In the future we'll have also (identifier NL* DOT  NL*)*
        RefType(NodeIdManager.nextId(), Token(), className())
    }

    private func nodeType(id: NodeId, typeParameterName: ?Token): TypeNode {
        if (helper.matches(TokenKind.LPAREN)) {
            // Function type, and maybe Tuple type in the future
            let paramTypes = ArrayList<TypeNode>()
            if (!helper.matches(TokenKind.RPAREN)) {
                while (true) {
                    paramTypes.add(nodeType(NodeIdManager.nextId(), None))
                    if (helper.matches(TokenKind.RPAREN)) {
                        break
                    } else if (!helper.matches(TokenKind.COMMA)) {
                        helper.error(helper.peek(),
                            "Expected ',' or ')' in function type, found '\u{001b}[31m${helper.peek().value}\u{001b}[0m'",
                            helper.current)
                    }
                }
            }
            helper.consume(TokenKind.ARROW, "Expect '->' in function type", helper.current)
            let returnType = nodeType(NodeIdManager.nextId(), None)
            FuncType(id, typeParameterName, paramTypes, returnType)
        } else {
            let typeName = helper.advance()
            let typeParamName = typeParameterName.getOrDefault({=> typeName})
            try {
                return PrimitiveType(id, typeParamName, typeName)
            } catch (_: IllegalArgumentException) {
                return RefType(id, typeParamName, typeName)
            }
        }
    }

    private func unnamedParameter(): FuncParam {
        if (helper.matches(TK.IDENTIFIER, TK.WILDCARD)) {
            let parameterName = helper.previous()
            helper.consume(TK.COLON, "Expect ':' after parameter name", helper.current)
            FuncParam(NodeIdManager.nextId(), nodeType(NodeIdManager.nextId(), parameterName))
        } else {
            throw helper.error(helper.peek(),
                "Expected unnamed parameter, found '\u{001b}[31m${helper.peek().value}\u{001b}[0m'", helper.current)
        }
    }

    func mainDefinition(): ?MainDecl {
        if (!helper.matches(TK.MAIN)) {
            return None
        }
        let start: (Token, Int64) = (helper.previous(), helper.current - 1)
        var parameter: ?FuncParam = None
        var parameters: Int64 = 0
        if (!helper.matches(TK.UNIT_LITERAL)) {
            helper.consume(TK.LPAREN, "Expect '(' after main.", helper.current)
            try {
                if (!helper.check(TK.RPAREN)) {
                    do {
                        if (parameters >= 1) {
                            throw helper.error(helper.peek(), "Can't have more than 1 parameter in main function.",
                                helper.current)
                        }
                        parameters++
                        parameter = unnamedParameter()

                    // TODO: For now, discards all other parameters other than the first one.
                    // TEMPORARY FIX, REMEMBER TO MAKE A REAL SOLUTION

                    } while (helper.matches(TK.COMMA))
                }
            } catch (error: ParseError) {
                helper.synchronize()
            }
            helper.consume(TK.RPAREN, "Expect ') after parameters.", helper.current)
        }

        var declType: ?TypeNode = None
        if (helper.matches(TK.COLON)) {
            declType = nodeType(NodeIdManager.nextId(), None)
        }

        try {
            let block: Block = block()
            return MainDecl(NodeIdManager.nextId(), block, parameter, declType)
        } catch (e: ConsumeError) {
            helper.pop()
            helper.error(start[0], "body of main function is missing", start[1])
            return MainDecl(NodeIdManager.nextId(), Block(), parameter, declType)
        }
    }

    private func variableDeclaration(): ?VarDecl {
        if (!helper.matches(TK.LET, TK.VAR)) {
            return None
        }
        let keyword: Token = helper.previous()

        helper.skipNL()
        let name: Token = helper.consume(TK.IDENTIFIER, "Expect variable name.", helper.current)

        var declType: ?TypeNode = None
        if (helper.matches(TK.COLON)) {
            declType = nodeType(NodeIdManager.nextId(), name)
        }

        var initializer: ?Expr = None
        if (helper.matches(TK.ASSIGN)) {
            initializer = expression()
        }

        VarDecl(NodeIdManager.nextId(), keyword, name, initializer, declType)
    }

    private func block(): Block {
        if (!helper.check(TK.LCURL)) {
            helper.consumeError(helper.peek(), helper.current, TK.LCURL, helper.peek().value)
            throw ConsumeError("No Block")
        }

        var nodes: ArrayList<Node> = ArrayList()
        helper.consume(TK.LCURL, "Expect '{' before block.", helper.current)
        let start: (Token, Int64) = (helper.peek(), helper.current)
        try {
            nodes = expressionOrDeclarations()
            helper.endStar()
            helper.consume(TK.RCURL, "Expect '}' after block.", helper.current)
        } catch (e: ParseError) {
            helper.synchronizeBlockRightCurl(start[0], start[1])
            reporter.unclosedDelimiterError(helper.peek(), start[0], start[1], helper.current)
        } catch (e: ConsumeError) {
            reporter.unclosedDelimiterError(helper.peek(), start[0], start[1], helper.current)
        }
        Block(NodeIdManager.nextId(), nodes)
    }

    private func expressionOrDeclarations(): ArrayList<Node> {
        let expressionOrDeclarations: ArrayList<Node> = ArrayList()
        helper.endStar()
        if (let Some(exprOrDecl) <- expressionOrDeclaration()) {
            expressionOrDeclarations.add(exprOrDecl)
            while (let Some(exprOrDecl) <- helper.tryParse<Node>(
                    {
                        =>
                            try {
                                helper.endPlus("", helper.peek(), helper.current)
                            } catch (_) {
                                helper.pop();
                                return None
                            }
                            expressionOrDeclaration()
                    }
                )) {
                expressionOrDeclarations.add(exprOrDecl)
            }
        }
        expressionOrDeclarations
    }

    private func expressionOrDeclaration(): ?Node {
        try {
            if (let Some(decl) <- declaration()) {
                return decl
            }
            if (let Some(expr) <- expression()) {
                return expr
            }
            if (helper.matches(TKH.END) || helper.check(TK.RCURL)) {
                return None
            }
            throw helper.error(helper.peek(),
                "Expected expression or declaration inside block, found '\u{001b}[31m${helper.peek().value}\u{001b}[0m'",
                helper.current)
        } catch (e: ParseError) {
            helper.synchronize()
        }
        None
    }

    private func whileExpr(): ?Expr {
        if (!helper.matches(TK.WHILE)) {
            return None
        }

        helper.skipNL()
        helper.consume(TK.LPAREN, "Expect '(' before condition.", helper.current)
        let start: (Token, Int64) = (helper.previous(), helper.current - 1)
        helper.skipNL()
        var condition: Expr
        try {
            condition = expectExpression(expression, "Expected condition after while.")
            helper.skipNL()
            helper.consume(TK.RPAREN, "Expect ')' after condition.", helper.current)
        } catch (e: ParseError) {
            helper.synchronizeBlockParenthesis(start[0], start[1])
            condition = Expr(NodeIdManager.nextId())
        }
        helper.skipNL()
        let block: Block = block()

        WhileExpr(NodeIdManager.nextId(), condition, block)
    }

    private func loopExpression(): ?Expr {
        if (let Some(whileExpr) <- whileExpr()) {
            return whileExpr
        }
        None
    }

    private func ifExpression(): ?Expr {
        if (!helper.matches(TK.IF)) {
            return None
        }
        helper.skipNL()
        helper.consume(TK.LPAREN, "Expect '(' before condition.", helper.current)
        let start: (Token, Int64) = (helper.previous(), helper.current - 1)
        helper.skipNL()
        var condition: Expr
        try {
            condition = expectExpression(expression, "Expected condition after while.")
            helper.skipNL()
            helper.consume(TK.RPAREN, "Expect ')' after condition.", helper.current)
        } catch (e: ParseError) {
            helper.synchronizeBlockParenthesis(start[0], start[1])
            condition = Expr(NodeIdManager.nextId())
        }
        helper.skipNL()

        let ifBlock: Block = block()
        let elseBranch: Expr = if (let Some(elseBranch) <- helper.tryParse<Expr>(
            {
                =>
                    helper.skipNL()
                    if (helper.matches(TK.ELSE)) {
                        helper.skipNL()
                        if (let Some(ifExpr) <- ifExpression()) {
                            return ifExpr
                        } else {
                            return block()
                        }
                    }
                    return None
            }
        )) {
            elseBranch
        } else {
            /*
             * Desugar if () { expr } to if () { expr; () } else { () }
             */
            ifBlock.nodes.add(LitConstExpr(NodeIdManager.nextId(), Token(TK.UNIT_LITERAL, "()", Position())))
            Block(NodeIdManager.nextId(),
                ArrayList<Node>([LitConstExpr(NodeIdManager.nextId(), Token(TK.UNIT_LITERAL, "()", Position()))]))
        }
        return IfExpr(NodeIdManager.nextId(), condition, ifBlock, elseBranch)
    }

    public func expression(): ?Expr {
        try {
            return assignmentExpression()
        } catch (e: Exception) {
            helper.synchronize()
            return None
        }
    }

    private func leftValueExpression(): ?Expr {
        return leftValueExpressionWithoutWildCard()
    }

    private func leftValueExpressionWithoutWildCard(): ?Expr {
        if (let Some(leftWithAssignable) <- helper.tryParse(
            {
                =>
                    if (let Some(lae) <- leftAuxExpression()) {
                        helper.skipNL()
                        var base: Expr = lae
                        var assignable: Bool = true
                        while (true) {
                            if (let Some(fieldAccess) <- fieldAccess(base)) {
                                base = fieldAccess
                                assignable = true
                                continue
                            }
                            if (let Some(callSuffix) <- callSuffix(base)) {
                                base = callSuffix
                                assignable = false
                                continue
                            }
                            break
                        }
                        if (assignable) {
                            return base
                        }
                        throw helper.error(helper.previous(), "The left part needs to be assignable!", helper.current - 1)
                    }
                    None
            }
        )) {
            return leftWithAssignable
        }
        return identifier()
    }

    private func leftAuxExpression(): ?Expr {
        if (let Some(identifier) <- identifier()) {
            return identifier
        }
        if (let Some(thisSuperExpression) <- thisSuperExpression()) {
            return thisSuperExpression
        }
        primitiveTypeExpr()
    }

    private func primitiveTypeExpr(): ?Expr {
        if (helper.matches(TKH.CHAR_LANG_TYPES)) {
            return PrimitiveTypeExpr(NodeIdManager.nextId(), helper.previous())
        }
        None
    }

    private func fieldAccess(baseExpr: Expr): ?Expr {
        return helper.tryParse(
            {
                =>
                    helper.skipNL()
                    if (helper.matches(TK.DOT)) {
                        helper.skipNL()
                        return MemberAccess(NodeIdManager.nextId(), baseExpr,
                            helper.consume(TK.IDENTIFIER, "Expected identifier after '.'", helper.current))
                    }
                    None
            }
        )
    }

    private func callSuffix(callee: Expr): ?Expr {
        let arguments: ArrayList<Argument> = ArrayList()
        if (helper.matches(TK.LPAREN)) {
            let start: (Token, Int64) = (helper.previous(), helper.current - 1)
            try {
                helper.skipNL()
                if (!helper.check(TK.RPAREN)) {
                    do {
                        helper.skipNL()
                        arguments.add(
                            Argument(
                                NodeIdManager.nextId(),
                                expectExpression(
                                    expression,
                                    "Expected expression inside call suffix."
                                )
                            )
                        )
                        helper.skipNL()
                    } while (helper.matches(TK.COMMA))
                }
                helper.consume(TK.RPAREN, "Expect ')' after arguments.", helper.current)
            } catch (e: ParseError) {
                helper.synchronizeCallParenthesis(start[0], start[1])
            } catch (e: ConsumeError) {
                reporter.unclosedDelimiterError(helper.peek(), start[0], start[1], helper.current)
            }
        } else if (!helper.matches(TK.UNIT_LITERAL)) {
            return None
        }
        CallExpr(NodeIdManager.nextId(), callee, arguments)
    }

    /*
     * Tries to parse an expression and throws an error with the given message if
     * no expression was found.
     */
    private func expectExpression<T>(function: () -> ?T, message: String): Expr where T <: Expr {
        return function().getOrThrow({
            => helper.error(helper.peek(), message, helper.current)
        })
    }

    private func assignmentExpression(): ?Expr {
        if (let Some(value) <- helper.tryParse(
            {
                =>
                    /*
                     * If I don't find the Assignment Operator I need to go back to
                     * include my left value expression to the expression I will
                     * eventually parse.
                     */
                    try {
                        if (let Some(value) <- leftValueExpression() && helper.matches(TKH.ASSIGNMENT_OPERATOR) && let Some(right) <- logicConjunctionExpression()) {
                            return AssignExpr(NodeIdManager.nextId(), value, right)
                        }
                    } catch (e: Exception) {
                        if (helper.check(TKH.ASSIGNMENT_OPERATOR)) {
                            throw e
                        }
                        helper.pop()
                    }
                    None
            }
        )) {
            return value
        }
        logicDisjunctionExpression()
    }

    private func identifier(): ?Expr {
        if (helper.matches(TK.IDENTIFIER)) {
            return RefExpr(NodeIdManager.nextId(), helper.previous())
        }
        None
    }

    private func logicDisjunctionExpression(): ?Expr {
        if (let Some(e) <- logicConjunctionExpression()) {
            var expr: Expr = e
            while (helper.matches(TK.OR)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(logicConjunctionExpression,
                    "Expected logicConjunctionExpression after '${oper.value}'")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func logicConjunctionExpression(): ?Expr {
        if (let Some(e) <- bitwiseDisjunctionExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TK.AND)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(bitwiseDisjunctionExpression,
                    "Expect bitwiseDisjunctionExpression after '${oper.value}'")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func bitwiseDisjunctionExpression(): ?Expr {
        if (let Some(e) <- bitwiseConjunctionExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TK.BITOR)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(bitwiseConjunctionExpression,
                    "Expect bitwiseConjuctionExpression after '${oper.value}'")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func bitwiseConjunctionExpression(): ?Expr {
        if (let Some(e) <- equalityComparisonExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TK.BITAND)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(equalityComparisonExpression,
                    "Expect equalityComparisonExpression after ${oper.value}")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func equalityComparisonExpression(): ?Expr {
        if (let Some(e) <- comparisonOrTypeExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TKH.EQUALITY_OPERATOR)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(comparisonOrTypeExpression,
                    "Expect comparisonOrTypeExpression after ${oper.value}")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func comparisonOrTypeExpression(): ?Expr {
        if (let Some(e) <- additiveExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TKH.COMPARISON_OPERATOR)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(additiveExpression, "Expect additiveExpression after '${oper.value}'")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func additiveExpression(): ?Expr {
        if (let Some(e) <- multiplicativeExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TKH.ADDITIVE_OPERATOR)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(multiplicativeExpression,
                    "Expect multiplicativeExpression after '${oper.value}'")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func multiplicativeExpression(): ?Expr {
        if (let Some(e) <- exponentExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TKH.MULTIPLICATIVE_OPERATOR)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(exponentExpression,
                    "Expect exponent expression after '${oper.value}'")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func exponentExpression(): ?Expr {
        if (let Some(e) <- prefixUnaryExpression()) {
            var expr: Expr = e
            while (helper.skipNLCompare(TKH.EXPONENT_OPERATOR)) {
                let oper: Token = helper.previous()
                helper.skipNL()
                let right: Expr = expectExpression(prefixUnaryExpression,
                    "Expected a prefixUnaryExpression after '**', found '\u{001b}[31m${helper.peek().value}\u{001b}[0m'")
                expr = BinaryExpr(NodeIdManager.nextId(), expr, oper, right)
            }
            return expr
        }
        None
    }

    private func prefixUnaryExpression(): ?Expr {
        // TODO: now an expression like --5 is ok but in the future
        // we will add the inc and dec operators that will be after this so that
        // the problem will be solved.
        if (helper.matches(TKH.PREFIX_UNARY_OPERATOR)) {
            let oper: Token = helper.previous()
            let right: Expr = expectExpression(prefixUnaryExpression,
                "Expected a postfixExpression after ${oper.value}, found '\u{001b}[31m${helper.peek().value}\u{001b}[0m'")
            return UnaryExpr(NodeIdManager.nextId(), oper, right)
        }
        postfixExpression()
    }

    private func postfixExpression(): ?Expr {
        let base: Expr
        if (let Some(e) <- atomicExpression()) {
            base = e
        } else if (let Some(e) <- helper.tryParse(
            {
                =>
                    if (let Some(primitiveTypeExpr) <- primitiveTypeExpr()) {
                        var base: Expr = primitiveTypeExpr
                        while (true) {
                            if (let Some(fieldAccess) <- fieldAccess(base)) {
                                base = fieldAccess
                                continue
                            }
                            if (let Some(callSuffix) <- callSuffix(base)) {
                                base = callSuffix
                                continue
                            }
                            break
                        }
                        return base
                    }
                    None
            }
        )) {
            base = e
        } else {
            return None
        }
        var expr: Expr = base
        while (true) {
            if (let Some(callSuffix) <- callSuffix(expr)) {
                expr = callSuffix
                continue
            }
            if (let Some(fieldAccess) <- fieldAccess(expr)) {
                expr = fieldAccess
                continue
            }
            break
        }
        return expr
    }

    private func atomicExpression(): ?Expr {
        if (helper.matches(TKH.LITERAL_CONSTANT)) {
            return LitConstExpr(NodeIdManager.nextId(), helper.previous())
        }
        if (let Some(ifExpr) <- ifExpression()) {
            return ifExpr
        }
        if (let Some(loop) <- loopExpression()) {
            return loop
        }
        if (let Some(jump) <- jumpExpression()) {
            return jump
        }
        if (let Some(i) <- identifier()) {
            return i
        }
        if (let Some(thisSuperExpression) <- thisSuperExpression()) {
            return thisSuperExpression
        }
        if (helper.matches(TK.LPAREN)) {
            helper.skipNL()
            let expr: Expr = expectExpression(expression, "Expect expression after '('")
            helper.skipNL()
            helper.consume(TK.RPAREN, "Expected ')' after expression.", helper.current)
            return ParenExpr(NodeIdManager.nextId(), expr)
        }
        None
    }

    private func thisSuperExpression(): ?Expr {
        if (helper.matches(TKH.THIS_SUPER)) {
            return ThisSuperExpr(NodeIdManager.nextId(), helper.previous())
        }
        None
    }

    private func returnExpr(): ?Expr {
        if (!helper.matches(TK.RETURN)) {
            return None
        }
        let keyword: Token = helper.previous()
        helper.skipNL()
        // TODO: Change return Expr to always have an expression, if expression is None then put ().
        ReturnExpr(NodeIdManager.nextId(), expression(), keyword)
    }

    private func jumpExpression(): ?Expr {
        if (let Some(retExpr) <- returnExpr()) {
            return retExpr
        }
        if (helper.matches(TK.CONTINUE, TK.BREAK)) {
            return JumpExpr(NodeIdManager.nextId(), helper.previous())
        }
        None
    }
}
