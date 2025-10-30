/**
 * Position.cj
 *
 * This is a helper file that helps you find where an ast is in the code.
 */

package cjcj.executor

import std.deriving.*
import cjcj.visitor.*
import cjcj.scanner.Token

@Derive[ToString]
public struct Position {
    public let name: String
    public let line: Int32
    public let column: Int32

    init(name: String, line: Int32, column: Int32) {
        this.name = name
        this.line = line
        this.column = column
    }

    init(name: String, tok: Token) {
        this.name = name
        this.line = tok.pos.line
        this.column = tok.pos.column
    }
}

public func getPosition(n: Node): Position {
    let getter = PositionGetter()
    n.traverse(getter)
}

class PositionGetter <: Visitor<Position> {
    public override func visit(n: Program): Position {
        n.decls.first.map({it => it.traverse(this)}).getOrDefault({=> Position("Block", 0, 0)})
    }

    public override func visit(n: BinaryExpr): Position {
        Position("BinaryExpr", n.oper)
    }

    public override func visit(n: UnaryExpr): Position {
        Position("UnaryExpr", n.oper)
    }

    public override func visit(n: ParenExpr): Position {
        n.parenthesizedExpr.traverse(this)
    }

    public override func visit(n: LitConstExpr): Position {
        Position("Literal", n.literal)
    }

    public override func visit(n: AssignExpr): Position {
        n.left.traverse(this)
    }

    public override func visit(n: RefExpr): Position {
        Position("RefExpr", n.identifier)
    }

    public override func visit(n: Block): Position {
        n.nodes.first.map({it => it.traverse(this)}).getOrDefault({=> Position("Block", 0, 0)})
    }

    public override func visit(n: IfExpr): Position {
        n.condition.traverse(this)
    }

    public override func visit(n: WhileExpr): Position {
        n.condition.traverse(this)
    }

    public override func visit(n: CallExpr): Position {
        n.callee.traverse(this)
    }

    public override func visit(n: ReturnExpr): Position {
        Position("ReturnExpr", n.keyword)
    }

    public override func visit(n: JumpExpr): Position {
        Position("JumpExpr", n.keyword)
    }

    public override func visit(n: VarDecl): Position {
        Position("VarDecl", n.identifier)
    }

    public override func visit(n: FuncParam): Position {
        Position("FuncParam", n.identifier)
    }

    public override func visit(n: FuncDecl): Position {
        Position("FuncDecl", n.identifier)
    }

    public override func visit(n: MainDecl): Position {
        Position("MainDecl", n.keyword)
    }

    public override func visit(n: ClassDecl): Position {
        Position("ClassDecl", n.identifier)
    }

    public override func visit(n: Body): Position {
        n.decls.first.map({it => it.traverse(this)}).getOrDefault({=> Position("Body", 0, 0)})
    }

    public override func visit(n: Argument): Position {
        n.expr.traverse(this)
    }

    public override func visit(n: TypeNode): Position {
        Position("TypeNode", n.typeName)
    }

    public override func visit(n: PrimitiveType): Position {
        Position("PrimitiveType", n.typeName)
    }

    public override func visit(n: RefType): Position {
        Position("RefType", n.typeName)
    }

    public override func visit(n: VariableReference): Position {
        Position("VariableReference", n.identifier)
    }

    public override func visit(n: FuncReference): Position {
        Position("FunctionReference", n.identifier)
    }

    public override func visit(n: ClassReference): Position {
        Position("ClassReference", n.identifier)
    }

    public override func visit(n: VarDeclWithRef): Position {
        Position("VarDeclWithRef", n.identifier)
    }

    public override func visit(n: FuncDeclWithRef): Position {
        Position("FuncDeclWithRef", n.identifier)
    }

    public override func visit(n: MainDeclWithRef): Position {
        Position("MainDeclWithRef", n.identifier)
    }

    public override func visit(n: ClassDeclWithRef): Position {
        Position("ClassDeclWithRef", n.identifier)
    }

    public override func visit(n: MemberAccess): Position {
        Position("MemberAccess", n.field)
    }

    public override func visit(n: PrimitiveTypeExpr): Position {
        Position("PrimitiveTypeExpr", n.keyword)
    }

    public override func visit(n: RefExprWithRef): Position {
        Position("RefExprWithRef", n.identifier)
    }

    public override func visit(n: ThisSuperExpr): Position {
        Position("ThisSuperExpr", n.keyword)
    }

    public override func visit(n: ThisSuperReference): Position {
        Position("ThisSuperReference", n.keyword)
    }

    public override func visit(n: CallExprWithRef): Position {
        n.callee.traverse(this)
    }

    public override func visit(n: MemberAccessWithRef): Position {
        Position("MemberAccessWithRef", n.field)
    }

    public override func visit(n: InterfaceDecl): Position {
        Position("InterfaceDecl", n.identifier)
    }

    public override func visit(n: InterfaceDeclWithRef): Position {
        Position("InterfaceDeclWithRef", n.identifier)
    }

    public override func visit(n: InterfaceReference): Position {
        Position("InterfaceReference", n.identifier)
    }
}
