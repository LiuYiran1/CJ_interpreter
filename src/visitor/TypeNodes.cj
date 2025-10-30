package cjcj.visitor

import cjcj.prettyPrinter.{PrettyPrinter, YamlPrinter}
import cjcj.scanner.*
import std.ast.Position
import std.collection.ArrayList

/*
    TODO: Make this abstract and try to remove the default constructors of the nodes that maybe we
    can avoid.
 */
public open class TypeNode <: Node {
    private var typeParameterName_: Token = Token()
    private var typeName_: Token = Token()

    public init() {
        this(NodeId())
    }

    public init(id: NodeId) {
        super(id)
    }

    public init(id: NodeId, typeParameterName: Token, typeName: Token) {
        super(id)
        typeParameterName_ = typeParameterName
        typeName_ = typeName
    }

    public open override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public open override func prettyPrint(_: PrettyPrinter): Unit {
    }

    public open override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("typeParameterName", typeParameterName.value)
        printer.print("typeName", typeName.value)
    }

    public mut prop typeParameterName: Token {
        get() {
            typeParameterName_
        }
        set(v) {
            typeParameterName_ = v
        }
    }

    public mut prop typeName: Token {
        get() {
            typeName_
        }
        set(v) {
            typeName_ = v
        }
    }
}

public class PrimitiveType <: TypeNode {
    public init(id: NodeId, typeParameterName: Token, typeName: Token) {
        super(
            id,
            typeParameterName,
            if (isPrimitive(typeName)) {
                typeName
            } else {
                throw IllegalArgumentException("${typeName.value} is not a primitive type.")
            }
        )
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)
        printer.append(typeName.value)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "PrimitiveType")
        super.yamlPrint(printer)
    }

    private func isPrimitive(typeName: Token): Bool {
        TokenKindHelper.CHAR_LANG_TYPES.iterator().any({t => t == typeName.kind})
    }
}

public class RefType <: TypeNode {
    public init(id: NodeId, typeParameterName: Token, typeName: Token) {
        super(id, typeParameterName, typeName)
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)
        printer.append(typeName.value)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "RefType")
        super.yamlPrint(printer)
    }
}

public class FuncType <: TypeNode {
    static let ARROW_TOKEN = Token(TokenKind.ARROW, "->", Position())

    private let paramTypes_: ArrayList<TypeNode>
    private let returnType_: TypeNode

    public init(id: NodeId, typeParameterName: ?Token, paramTypes: ArrayList<TypeNode>, returnType: TypeNode) {
        super(id, typeParameterName.getOrDefault({=> ARROW_TOKEN}), ARROW_TOKEN)
        paramTypes_ = paramTypes
        returnType_ = returnType
    }

    public prop paramTypes: ArrayList<TypeNode> {
        get() {
            paramTypes_
        }
    }

    public prop returnType: TypeNode {
        get() {
            returnType_
        }
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter) {
        super.prettyPrint(printer)
        printer.append("fn(")
        for ((i, paramType) in paramTypes_.iterator().enumerate()) {
            paramType.prettyPrint(printer)
            if (i < paramTypes_.size - 1) {
                printer.append(", ")
            }
        }
        printer.append(") -> ")
        returnType_.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "FuncType")
        super.yamlPrint(printer)
        printer.printList("paramTypes", paramTypes_)
        printer.printObject("returnType", returnType_)
    }

}
