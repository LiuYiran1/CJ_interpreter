package cjcj.visitor

import cjcj.prettyPrinter.{PrettyPrinter, YamlPrinter}
import cjcj.scanner.Token
import cjcj.scanner.TokenKind
import std.collection.ArrayList

public abstract class Decl <: Node & Equatable<Decl> {
    protected var identifier_: Token = Token()
    protected var keyword_: Token = identifier_
    protected var declType_: ?TypeNode = None

    init() {
        this(NodeId())
    }

    init(id: NodeId) {
        super(id)
    }

    init(id: NodeId, declType: ?TypeNode) {
        this(id)
        declType_ = declType
    }

    init(id: NodeId, keyword: Token, identifier: Token) {
        this(id)
        identifier_ = identifier
        keyword_ = keyword
    }

    init(id: NodeId, keyword: Token, identifier: Token, declType: ?TypeNode) {
        this(id, keyword, identifier)
        declType_ = declType
    }

    //Constructor for constructors, they have no name
    init(id: NodeId, keyword: Token) {
        super(id)
        keyword_ = keyword
    }

    // Copy constructor
    init(decl: Decl) {
        this(decl.id)
        this.identifier_ = decl.identifier_
        this.keyword_ = decl.keyword_
    }

    public open override func traverse<R>(_: Visitor<R>): R {
        throw UnsupportedException("Traverse for Decl is not implemented")
    }

    public mut open prop identifier: Token {
        get() {
            identifier_
        }
        set(v) {
            identifier_ = v
        }
    }

    public mut open prop keyword: Token {
        get() {
            keyword_
        }
        set(v) {
            keyword_ = v
        }
    }

    public mut prop declType: ?TypeNode {
        get() {
            declType_
        }
        set(v) {
            declType_ = v
        }
    }

    public open override func prettyPrint(printer: PrettyPrinter) {
        if (keyword.kind != TokenKind.ILLEGAL) {
            printer.append(keyword.value + " ")
        }
        if (identifier.kind != TokenKind.ILLEGAL) {
            printer.append(identifier.value)
        }
    }

    public open override func yamlPrint(printer: YamlPrinter): Unit {
        if (keyword.kind != TokenKind.ILLEGAL) {
            printer.print("keyword", keyword)
        }
        if (keyword.kind != TokenKind.ILLEGAL) {
            printer.print("identifier", identifier)
        }
        printer.printOptionalObject("declType", declType)
    }

    public operator override func ==(other: Decl) {
        id == other.id
    }

    public operator override func !=(other: Decl) {
        !(this == other)
    }
}

public open class VarDecl <: Decl {
    private var initializer_: ?Expr

    public init() {
        this(NodeId(), Token(), Token())
    }

    public init(id: NodeId, keyword: Token, identifier: Token) {
        this(id, keyword, identifier, None)
    }

    public init(id: NodeId, keyword: Token, identifier: Token, initializer: ?Expr) {
        this(id, keyword, identifier, initializer, None)
    }

    public init(id: NodeId, keyword: Token, identifier: Token, initializer: ?Expr, declType: ?TypeNode) {
        super(id, keyword, identifier, declType)
        initializer_ = initializer
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop initializer: ?Expr {
        get() {
            initializer_
        }
        set(v) {
            initializer_ = v
        }
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)
        if (let Some(dtype) <- declType) {
            printer.append(": ")
            dtype.prettyPrint(printer)
        }
        printer.append("${if (initializer.isSome()) { " = " } else { "" }}")
        if (let Some(ini) <- initializer) {
            ini.prettyPrint(printer)
        }
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "VarDecl")
        super.yamlPrint(printer)
        printer.printOptionalObject("initializer", initializer)
    }
}

public open class MainDecl <: Decl {
    private var block_: Block
    private var param_: ?FuncParam

    public init() {
        this(NodeId(), Block(), None, None)
    }

    public MainDecl(id: NodeId, block: Block, param: ?FuncParam, declType: ?TypeNode) {
        super(id, declType)
        this.block_ = block
        this.param_ = param
        this.declType_ = declType
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)
        printer.append("main(")
        if (let Some(a) <- param) {
            a.prettyPrint(printer)
        }
        printer.append(")")

        if (let Some(dtype) <- declType) {
            printer.append(": ")
            dtype.prettyPrint(printer)
        }
        printer.append(" ")
        block_.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "MainDecl")
        super.yamlPrint(printer)
        printer.printOptionalObject("param", param)
        printer.printObject("block", block)
    }

    public mut prop block: Block {
        get() {
            block_
        }
        set(v) {
            block_ = v
        }
    }

    public mut prop param: ?FuncParam {
        get() {
            param_
        }
        set(v) {
            param_ = v
        }
    }
}

public class FuncParam <: Decl {
    private var paramType_: TypeNode

    public init() {
        this(NodeId(), TypeNode())
    }

    public init(id: NodeId, paramType: TypeNode) {
        super(id)
        paramType_ = paramType
    }

    public init(id: NodeId, keyword: Token, paramType: TypeNode) {
        super(id, keyword)
        paramType_ = paramType
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        printer.append(paramType.typeParameterName.value + ": ")
        paramType.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "FuncParam")
        super.yamlPrint(printer)
        printer.print("name", name)
        printer.printObject("paramType", paramType)
    }

    public mut prop paramType: TypeNode {
        get() {
            paramType_
        }
        set(v) {
            paramType_ = v
        }
    }

    public prop name: Token {
        get() {
            paramType.typeParameterName
        }
    }

    public func isMemberParam() {
        return keyword.kind != TokenKind.ILLEGAL
    }
}

public open class FuncDecl <: Decl {
    private var block_: ?Block
    private var params_: ArrayList<FuncParam>

    public init() {
        this(NodeId(), Token(), Token(), Block(), ArrayList(), None)
    }

    public init(id: NodeId, keyword: Token, identifier: Token, block: ?Block, params: ArrayList<FuncParam>,
        declType: ?TypeNode) {
        super(id, keyword, identifier, declType)
        this.block_ = block
        this.params_ = params
        this.declType_ = declType
    }

    public init(id: NodeId, keyword: Token, block: ?Block, params: ArrayList<FuncParam>) {
        this(id, keyword, Token(), block, params, None)
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)
        printer.append("(")
        if (!params.isEmpty()) {
            params[0].prettyPrint(printer)
            for (i in 1..params.size) {
                printer.append(", ")
                params[i].prettyPrint(printer)
            }
        }
        printer.append(")")
        if (let Some(dtype) <- declType) {
            printer.append(": ")
            dtype.prettyPrint(printer)
        }
        printer.append(" ")
        if (let Some(realBlock) <- block_) {
            realBlock.prettyPrint(printer)
        }
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "FuncDecl")
        super.yamlPrint(printer)
        printer.printList("params", params)
        printer.printOptionalObject("block", block)
    }

    public mut prop block: ?Block {
        get() {
            block_
        }
        set(v) {
            block_ = v
        }
    }

    public mut prop params: ArrayList<FuncParam> {
        get() {
            params_
        }
        set(v) {
            params_ = v
        }
    }
}

public open class ClassDecl <: Decl {
    private let body_: Body
    private let superTypes_: ArrayList<TypeNode>

    public init(id: NodeId, keyword: Token, identifier: Token, body: Body, superTypes: ArrayList<TypeNode>) {
        super(id, keyword, identifier)
        body_ = body
        superTypes_ = superTypes
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)

        if (!superTypes.isEmpty()) {
            printer.append(" <: ")
            printer.append(superTypes[0].typeName.value)
            for (i in 1..superTypes.size) {
                printer.append(" & ")
                superTypes[i].prettyPrint(printer)
            }
        }
        printer.append(" ")
        body.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "ClassDecl")
        super.yamlPrint(printer)
        printer.printList("superTypes", superTypes)
        printer.printObject("body", body)
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop body: Body {
        get() {
            body_
        }
    }

    public prop superTypes: ArrayList<TypeNode> {
        get() {
            superTypes_
        }
    }
}

public open class InterfaceDecl <: Decl {
    private let body_: Body
    private let superTypes_: ArrayList<TypeNode>

    public init(id: NodeId, keyword: Token, identifier: Token, body: Body, superTypes: ArrayList<TypeNode>) {
        super(id, keyword, identifier)
        body_ = body
        superTypes_ = superTypes
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)

        if (!superTypes.isEmpty()) {
            printer.append(" <: ")
            printer.append(superTypes[0].typeName.value)
            for (i in 1..superTypes.size) {
                printer.append(" & ")
                superTypes[i].prettyPrint(printer)
            }
        }

        printer.append(" ")
        body.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "InterfaceDecl")
        super.yamlPrint(printer)
        printer.printList("superTypes", superTypes)
        printer.printObject("body", body)
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop superTypes: ArrayList<TypeNode> {
        get() {
            superTypes_
        }
    }

    public prop body: Body {
        get() {
            body_
        }
    }
}
