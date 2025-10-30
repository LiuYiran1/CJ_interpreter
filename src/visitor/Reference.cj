package cjcj.visitor

import cjcj.prettyPrinter.{PrettyPrinter, YamlPrinter}
import cjcj.scanner.Token
import std.collection.*

/*
 * Reference nodes represent references to variables, functions, . . . inside the ASG.
 */
public abstract class Reference <: Expr & Equatable<Reference> & ToString {
    private var identifier_: Token
    private var effectiveType_: ?Type

    public Reference(id: NodeId, identifier: Token, effectiveType: ?Type) {
        super(id)
        identifier_ = identifier
        effectiveType_ = effectiveType
    }

    public open override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append(identifier.value)
    }

    public open override func yamlPrint(_: YamlPrinter): Unit {
        throw UnsupportedException("Unimplemented method")
    }

    public open override func traverse<R>(_: Visitor<R>): R {
        throw UnsupportedException("Unimplemented method")
    }

    public operator func ==(rhs: Reference): Bool {
        id.id == rhs.id.id
    }

    public func toString() {
        identifier.value.toString()
    }

    public mut prop identifier: Token {
        get() {
            identifier_
        }
        set(v) {
            identifier_ = v
        }
    }

    public mut prop effectiveType: ?Type {
        get() {
            effectiveType_
        }
        set(v) {
            effectiveType_ = v
        }
    }
}

public class VariableReference <: Reference {
    private let keyword_: Token

    public init(id: NodeId, identifier: Token, keyword: Token) {
        super(id, identifier, None)
        keyword_ = keyword
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop keyword: Token {
        get() {
            keyword_
        }
    }
}

public class FuncReference <: Reference & Equatable<FuncReference> {
    private var paramRef_: ?ArrayList<VariableReference> = None
    private var block_: ?Block = None

    public FuncReference(id: NodeId, identifier: Token) {
        super(id, identifier, None)
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public operator func ==(other: FuncReference): Bool {
        id == other.id
    }

    public operator func !=(other: FuncReference): Bool {
        id != other.id
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        super.prettyPrint(printer)
    }

    public mut prop block: ?Block {
        get() {
            block_
        }
        set(v) {
            block_ = v
        }
    }

    public mut prop paramRef: ?ArrayList<VariableReference> {
        get() {
            paramRef_
        }
        set(v) {
            paramRef_ = v
        }
    }
}

public open class ClassReference <: Reference {
    private var parent_: ?ClassReference = None
    private let parentInterfaces_: ArrayList<InterfaceReference>
    private let isOpen_: Bool

    public init(id: NodeId, identifier: Token, isOpen: Bool) {
        this(id, identifier, isOpen, ArrayList<InterfaceReference>())
    }
    public init(id: NodeId, identifier: Token, isOpen: Bool, parentInterfaces: ArrayList<InterfaceReference>) {
        super(id, identifier, None)
        isOpen_ = isOpen
        parentInterfaces_ = parentInterfaces
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop parent: ?ClassReference {
        get() {
            parent_
        }
        set(v) {
            parent_ = v
        }
    }

    public prop parentInterfaces: ArrayList<InterfaceReference> {
        get() {
            parentInterfaces_
        }
    }

    public prop isOpen: Bool {
        get() {
            isOpen_
        }
    }
}

public open class InterfaceReference <: Reference {
    private let parents_: ArrayList<InterfaceReference>

    public init(id: NodeId, identifier: Token, parents: ArrayList<InterfaceReference>) {
        super(id, identifier, None)
        parents_ = parents
    }

    public init(id: NodeId, identifier: Token) {
        this(id, identifier, ArrayList<InterfaceReference>())
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop parents: ArrayList<InterfaceReference> {
        get() {
            parents_
        }
    }
}

public class MainReference <: Reference {
    private var paramRef_: ?VariableReference = None

    public init(id: NodeId) {
        super(id, Token(), None)
    }

    public mut prop paramRef: ?VariableReference {
        get() {
            paramRef_
        }
        set(v) {
            paramRef_ = v
        }
    }
}

public class ThisSuperReference <: Reference {
    private let keyword_: Token
    private var classReference_: ?ClassReference = None

    public init(id: NodeId, keyword: Token) {
        super(id, Token(), None)
        keyword_ = keyword
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append(keyword.value)
    }

    public prop keyword: Token {
        get() {
            keyword_
        }
    }

    public mut prop classReference: ?ClassReference {
        get() {
            classReference_
        }
        set(v) {
            classReference_ = v
        }
    }
}

public class VarDeclWithRef <: VarDecl {
    private let ref_: VariableReference

    public init(id: NodeId, keyword: Token, identifier: Token, ref: VariableReference) {
        this(id, keyword, identifier, ref, None, None)
    }

    public init(
        id: NodeId,
        keyword: Token,
        identifier: Token,
        ref: VariableReference,
        initializer: Expr
    ) {
        this(id, keyword, identifier, ref, initializer, None)
    }

    public init(
        id: NodeId,
        keyword: Token,
        identifier: Token,
        ref: VariableReference,
        declType: TypeNode
    ) {
        this(id, keyword, identifier, ref, None, declType)
    }

    public init(
        id: NodeId,
        keyword: Token,
        identifier: Token,
        ref: VariableReference,
        initializer: ?Expr,
        declType: ?TypeNode
    ) {
        super(id, keyword, identifier, initializer, declType)
        ref_ = ref
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop ref: VariableReference {
        get() {
            ref_
        }
    }
}

public class FuncDeclWithRef <: FuncDecl {
    private let funcRef_: FuncReference

    public init(id: NodeId, keyword: Token, block: ?Block, params: ArrayList<FuncParam>, funcRef: FuncReference) {
        this(id, keyword, Token(), block, params, None, funcRef)
    }

    public FuncDeclWithRef(id: NodeId, keyword: Token, identifier: Token, block: ?Block, params: ArrayList<FuncParam>,
        declType: ?TypeNode, funcRef: FuncReference) {
        super(id, keyword, identifier, block, params, declType)
        funcRef_ = funcRef
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop funcRef: FuncReference {
        get() {
            funcRef_
        }
    }
}

public class MainDeclWithRef <: MainDecl {
    private let mainRef_: MainReference

    public MainDeclWithRef(id: NodeId, block: Block, param: ?FuncParam, declType: ?TypeNode, mainRef: MainReference) {
        super(id, block, param, declType)
        mainRef_ = mainRef
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop mainRef: MainReference {
        get() {
            mainRef_
        }
    }
}

public class ClassDeclWithRef <: ClassDecl {
    private let ref_: ClassReference

    public init(id: NodeId, keyword: Token, identifier: Token, body: Body, superTypes: ArrayList<TypeNode>,
        ref: ClassReference) {
        super(id, keyword, identifier, body, superTypes)
        ref_ = ref
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop ref: ClassReference {
        get() {
            ref_
        }
    }
}

public class RefExprWithRef <: RefExpr {
    private var ref_: ?Reference

    public init(id: NodeId, identifier: Token) {
        this(id, identifier, None)
    }

    public init(id: NodeId, identifier: Token, ref: ?Reference) {
        super(id, identifier)
        ref_ = ref
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop ref: ?Reference {
        get() {
            ref_
        }
        set(v) {
            ref_ = v
        }
    }
}

public class CallExprWithRef <: CallExpr {
    private var ref_: ?FuncReference = None

    public init(id: NodeId, callee: Node, arguments: ArrayList<Argument>) {
        super(id, callee, arguments)
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop ref: ?FuncReference {
        get() {
            ref_
        }
        set(v) {
            ref_ = v
        }
    }
}

public class MemberAccessWithRef <: MemberAccess {
    private var ref_: ?ClassReference = None

    public init(id: NodeId, baseExpr: Node, field: Token) {
        super(id, baseExpr, field)
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop ref: ?ClassReference {
        get() {
            ref_
        }
        set(v) {
            ref_ = v
        }
    }
}

public class InterfaceDeclWithRef <: InterfaceDecl {
    private var ref_: InterfaceReference

    public init(id: NodeId, keyword: Token, identifier: Token, body: Body, superTypes: ArrayList<TypeNode>,
        ref: InterfaceReference) {
        super(id, keyword, identifier, body, superTypes)
        ref_ = ref
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public prop ref: InterfaceReference {
        get() {
            ref_
        }
    }
}
