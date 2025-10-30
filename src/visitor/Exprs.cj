package cjcj.visitor

import cjcj.prettyPrinter.{PrettyPrinter, YamlPrinter}
import cjcj.scanner.Token
import cjcj.scanner.TokenKind
import std.collection.ArrayList

public open class Expr <: Node {
    public init() {
        super(NodeId())
    }

    public init(id: NodeId) {
        super(id)
    }

    public open override func traverse<R>(_: Visitor<R>): R {
        throw UnsupportedException("Unimplemented method")
    }

    public open override func prettyPrint(_: PrettyPrinter): Unit {}

    public open func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "Expr")
        let valuePrinter = PrettyPrinter()
        prettyPrint(valuePrinter)
        printer.print("value", '"' + valuePrinter.toString() + '"')
    }
}

public class BinaryExpr <: Expr {
    private var left_: Node
    private var oper_: Token
    private var right_: Node

    public init() {
        this(NodeId(), Expr(), Token(), Expr())
    }

    public BinaryExpr(id: NodeId, left: Node, oper: Token, right: Node) {
        super(id)
        left_ = left
        oper_ = oper
        right_ = right
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        left.prettyPrint(printer)
        printer.append(" ${oper.value} ")
        right.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "BinaryExpr")
        printer.printObject("left", left)
        printer.print("oper", oper.value)
        printer.printObject("right", right)
    }

    public mut prop left: Node {
        get() {
            left_
        }
        set(v) {
            left_ = v
        }
    }

    public mut prop oper: Token {
        get() {
            oper_
        }
        set(v) {
            oper_ = v
        }
    }

    public mut prop right: Node {
        get() {
            right_
        }
        set(v) {
            right_ = v
        }
    }
}

public class ParenExpr <: Expr {
    private var parenthesizedExpr_: Expr

    public init() {
        this(NodeId(), Expr())
    }

    public ParenExpr(id: NodeId, parenthesizedExpr: Expr) {
        super(id)
        parenthesizedExpr_ = parenthesizedExpr
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        printer.append("(")
        parenthesizedExpr.prettyPrint(printer)
        printer.append(")")
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "ParenExpr")
        printer.printObject("parenthesizedExpr", parenthesizedExpr)
    }

    public mut prop parenthesizedExpr: Expr {
        get() {
            parenthesizedExpr_
        }
        set(v) {
            parenthesizedExpr_ = v
        }
    }
}

public class LitConstExpr <: Expr {
    private var literal_: Token

    public init() {
        this(NodeId(), Token())
    }

    public LitConstExpr(id: NodeId, literal: Token) {
        super(id)
        literal_ = literal
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        match (literal.kind) {
            case TokenKind.STRING_LITERAL => printer.append("\"" + literal.value + "\"")
            case _ => printer.append(literal.value)
        }
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "LitConstExpr")
        printer.print("literal", '"' + literal.value + '"')
    }

    public mut prop literal: Token {
        get() {
            literal_
        }
        set(v) {
            literal_ = v
        }
    }
}

public class UnaryExpr <: Expr {
    private var oper_: Token
    private var right_: Expr

    public init() {
        this(NodeId(), Token(), Expr())
    }

    public UnaryExpr(id: NodeId, oper: Token, right: Expr) {
        super(id)
        oper_ = oper
        right_ = right
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        printer.append("${oper.value}")
        right.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "UnaryExpr")
        printer.print("oper", oper.value)
        printer.printObject("right", right)
    }

    public mut prop oper: Token {
        get() {
            oper_
        }
        set(v) {
            oper_ = v
        }
    }

    public mut prop right: Expr {
        get() {
            right_
        }
        set(v) {
            right_ = v
        }
    }
}

public class AssignExpr <: Expr {
    private var left_: Expr
    private var right_: Expr

    public init() {
        this(NodeId(), Expr(), Expr())
    }

    public AssignExpr(id: NodeId, left: Expr, value: Expr) {
        super(id)
        left_ = left
        right_ = value
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        left.prettyPrint(printer)
        printer.append(" = ")
        right.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "AssignExpr")
        printer.printObject("left", left)
        printer.printObject("right", right)
    }

    public mut prop left: Expr {
        get() {
            left_
        }
        set(v) {
            left_ = v
        }
    }

    public mut prop right: Expr {
        get() {
            right_
        }
        set(v) {
            right_ = v
        }
    }
}

public open class RefExpr <: Expr {
    private var identifier_: Token

    public RefExpr(id: NodeId, identifier: Token) {
        super(id)
        identifier_ = identifier
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop identifier: Token {
        get() {
            identifier_
        }
        set(v) {
            identifier_ = v
        }
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append(identifier.value)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "RefExpr")
        printer.print("identifier", identifier.value)
    }
}

public class Block <: Expr {
    private var nodes_: ArrayList<Node>

    public init() {
        this(NodeId(), ArrayList<Node>())
    }

    public Block(id: NodeId, nodes: ArrayList<Node>) {
        super(id)
        nodes_ = nodes
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        printer.append("{")
        if (!nodes.isEmpty()) {
            printer.indent()
            printer.append("\n")
            nodes[0].prettyPrint(printer)
            nodes.iterator().enumerate().filter({v => v[0] > 0}).map({v => v[1]}).forEach(
                {
                    n =>
                        printer.append("\n")
                        n.prettyPrint(printer)
                }
            )
            printer.unindent()
        }
        printer.append("\n}\n")
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "Block")
        printer.printList("nodes", nodes)
    }

    public mut prop nodes: ArrayList<Node> {
        get() {
            nodes_
        }
        set(v) {
            nodes_ = v
        }
    }
}

public class IfExpr <: Expr {
    private var condition_: Expr
    private var ifBlock_: Block
    private var elseBranch_: Expr

    public init() {
        this(NodeId(), Expr(), Block(), Expr())
    }

    public init(id: NodeId, condition: Expr, ifBlock: Block) {
        this(id, condition, ifBlock, Expr())
    }

    public IfExpr(id: NodeId, condition: Expr, ifBlock: Block, elseBranch: Expr) {
        super(id)
        condition_ = condition
        ifBlock_ = ifBlock
        elseBranch_ = elseBranch
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        printer.append("if (")
        condition.prettyPrint(printer)
        printer.append(") ")
        ifBlock.prettyPrint(printer)
        printer.append("else ")
        elseBranch.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "IfExpr")
        printer.printObject("condition", condition)
        printer.printObject("ifBlock", ifBlock)
        printer.printObject("elseBranch", elseBranch)
    }

    public mut prop condition: Expr {
        get() {
            condition_
        }
        set(v) {
            condition_ = v
        }
    }

    public mut prop ifBlock: Block {
        get() {
            ifBlock_
        }
        set(v) {
            ifBlock_ = v
        }
    }

    public mut prop elseBranch: Expr {
        get() {
            elseBranch_
        }
        set(v) {
            elseBranch_ = v
        }
    }
}

public class WhileExpr <: Expr {
    private var condition_: Expr
    private var block_: Block

    public init() {
        this(NodeId(), Expr(), Block())
    }

    public WhileExpr(id: NodeId, condition: Expr, block: Block) {
        super(id)
        condition_ = condition
        block_ = block
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        printer.append("while (")
        condition.prettyPrint(printer)
        printer.append(") ")
        block.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "WhileExpr")
        printer.printObject("condition", condition)
        printer.printObject("block", block)
    }

    public mut prop condition: Expr {
        get() {
            condition_
        }
        set(v) {
            condition_ = v
        }
    }

    public mut prop block: Block {
        get() {
            block_
        }
        set(v) {
            block_ = v
        }
    }
}

public open class CallExpr <: Expr {
    private let callee_: Node
    private var arguments_: ArrayList<Argument>

    public init() {
        this(NodeId(), Expr(), ArrayList())
    }

    public CallExpr(id: NodeId, callee: Node, arguments: ArrayList<Argument>) {
        super(id)
        callee_ = callee
        arguments_ = arguments
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public open override func prettyPrint(printer: PrettyPrinter): Unit {
        callee.prettyPrint(printer)
        printer.append("(")
        if (!arguments.isEmpty()) {
            arguments[0].prettyPrint(printer)
            arguments.iterator().enumerate().filter({a => a[0] > 0}).map({a => a[1]}).forEach(
                {
                    a =>
                        printer.append(", ");
                        a.prettyPrint(printer)
                }
            )
        }
        printer.append(")")
    }

    public open override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "CallExpr")
        printer.printObject("callee", callee)
        printer.printList("arguments", arguments)
    }

    public prop callee: Node {
        get() {
            callee_
        }
    }
    public mut prop arguments: ArrayList<Argument> {
        get() {
            arguments_
        }
        set(v) {
            arguments_ = v
        }
    }
}

public class ReturnExpr <: Expr {
    private var expr_: ?Expr
    private var keyword_: Token

    public init() {
        this(NodeId(), None, Token())
    }

    public ReturnExpr(id: NodeId, value: ?Expr, keyword: Token) {
        super(id)
        expr_ = value
        keyword_ = keyword
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append(keyword.value + " ")
        if (let Some(e) <- expr) {
            e.prettyPrint(printer)
        }
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "ReturnExpr")
        printer.printOptionalObject("expr", expr)
        printer.print("keyword", keyword.value)
    }

    public mut prop expr: ?Expr {
        get() {
            expr_
        }
        set(v) {
            expr_ = v
        }
    }

    public mut prop keyword: Token {
        get() {
            keyword_
        }
        set(v) {
            keyword_ = v
        }
    }
}

public class JumpExpr <: Expr {
    private var keyword_: Token

    public init() {
        this(NodeId(), Token())
    }

    public JumpExpr(id: NodeId, keyword: Token) {
        super(id)
        keyword_ = keyword
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append(keyword.value)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "JumpExpr")
        printer.print("keyword", keyword.value)
    }

    public mut prop keyword: Token {
        get() {
            keyword_
        }
        set(v) {
            keyword_ = v
        }
    }
}

public open class MemberAccess <: Expr {
    private var baseExpr_: Node
    private var field_: Token

    public init() {
        this(NodeId(), Expr(), Token())
    }

    public MemberAccess(id: NodeId, baseExpr: Node, field: Token) {
        super(id)
        baseExpr_ = baseExpr
        field_ = field
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        baseExpr.prettyPrint(printer)
        printer.append(".${field.value}")
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "MemberAccess")
        printer.printObject("baseExpr", baseExpr)
        printer.print("field", field.value)
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop baseExpr: Node {
        get() {
            baseExpr_
        }
        set(v) {
            baseExpr_ = v
        }
    }

    public mut prop field: Token {
        get() {
            field_
        }
        set(v) {
            field_ = v
        }
    }
}

public class PrimitiveTypeExpr <: Expr {
    private var keyword_: Token

    public init() {
        this(NodeId(), Token())
    }

    public PrimitiveTypeExpr(id: NodeId, keyword: Token) {
        super(id)
        keyword_ = keyword
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append(keyword.value)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "PrimitiveTypeExpr")
        printer.print("keyword", keyword.value)
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop keyword: Token {
        get() {
            keyword_
        }
        set(v) {
            keyword_ = v
        }
    }
}

public class ThisSuperExpr <: Expr {
    private var keyword_: Token

    public init() {
        this(NodeId(), Token())
    }

    public ThisSuperExpr(id: NodeId, keyword: Token) {
        super(id)
        keyword_ = keyword
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append(keyword.value)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "ThisSuperExpr")
        printer.print("keyword", keyword.value)
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop keyword: Token {
        get() {
            keyword_
        }
        set(v) {
            keyword_ = v
        }
    }
}
