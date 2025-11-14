package cjcj.visitor

import cjcj.prettyPrinter.{PrettyPrinter, YamlPrintable, YamlPrinter}
import std.collection.ArrayList
import std.deriving.Derive

@Derive[Equatable]
public struct NodeId <: Hashable {
    public let id: Int64

    // Default initializer with a default ID.
    public init() {
        this(0)
    }

    public NodeId(id: Int64) {
        this.id = id
    }

    public func hashCode(): Int64 {
        return id
    }
}

public abstract class Node <: Hashable & Equatable<Node> & YamlPrintable {
    private var id_: NodeId

    public Node(id: NodeId) {
        id_ = id
    }

    public func traverse<R>(v: Visitor<R>): R

    /*
     * Print the node and its children as a piece of Cangjie code.
     */
    public func prettyPrint(printer: PrettyPrinter): Unit

    public func yamlPrint(printer: YamlPrinter): Unit

    public func prettyPrint(): String {
        let printer: PrettyPrinter = PrettyPrinter()
        prettyPrint(printer)
        return printer.toString()
    }

    public func yamlPrint(): String {
        let printer: YamlPrinter = YamlPrinter()
        yamlPrint(printer)
        return printer.toString()
    }

    public mut prop id: NodeId {
        get() {
            id_
        }
        set(v) {
            id_ = v
        }
    }

    public func hashCode(): Int64 {
        id.hashCode()
    }

    public operator override func ==(other: Node): Bool {
        id == other.id
    }

    public operator override func !=(other: Node): Bool {
        !(this == other)
    }
}

public class Argument <: Node {
    private var expr_: Node

    public Argument(id: NodeId, expr: Node) {
        super(id)
        expr_ = expr
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        expr.prettyPrint(printer)
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "Argument")
        printer.printObject("expr", expr)
    }

    public mut prop expr: Node {
        get() {
            expr_
        }
        set(v) {
            expr_ = v
        }
    }
}

public class Program <: Node {
    private var decls_: ArrayList<Decl>

    public Program(id: NodeId, decls: ArrayList<Decl>) {
        super(id)
        decls_ = decls
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        decls.iterator().forEach(
            {
                d =>
                    d.prettyPrint(printer)
                    printer.append("\n")
            }
        )
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "Program")
        printer.printList("decls", decls)
    }

    public mut prop decls: ArrayList<Decl> {
        get() {
            decls_
        }
        set(v) {
            decls_ = v
        }
    }
}

public class Body <: Node {
    private var decls_: ArrayList<Decl>

    public init() {
        this(NodeId(), ArrayList())
    }

    public init(id: NodeId, decls: ArrayList<Decl>) {
        super(id)
        decls_ = decls
    }

    public override func prettyPrint(printer: PrettyPrinter): Unit {
        printer.append("{")
        printer.indent()
        printer.append("\n")
        decls.iterator().forEach(
            {
                d =>
                    d.prettyPrint(printer)
                    printer.append("\n")
            }
        )
        printer.unindent()
        printer.append("\n}")
    }

    public override func yamlPrint(printer: YamlPrinter): Unit {
        printer.print("type", "Body")
        printer.printList("decls", decls)
    }

    public override func traverse<R>(v: Visitor<R>): R {
        v.visit(this)
    }

    public mut prop decls: ArrayList<Decl> {
        get() {
            decls_
        }
        set(v) {
            decls_ = v
        }
    }
}
