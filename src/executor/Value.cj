package cjcj.executor

import std.deriving.Derive
import cjcj.visitor.*

// This is a very simple representation of values in the interpreter.
// You may need to extend or modify it depending on your design.
// Depending on your design, you may even need to repackage it with another class.
@Derive[ToString]
public enum Value {
    | VInteger(Int64)
    | VString(String)
    | VBoolean(Bool)
    | VUnit
    | VFunction(FuncValue)
    | VMain(MainValue)

    public func toValueString(): String {
        match (this) {
            case VInteger(i) => return i.toString()
            case VString(s) => return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
            case VBoolean(b) => return b.toString()
            case VUnit => return "()"
            case VFunction(f) => return "func"
            case VMain(m) => return "main"
        }
    }

    static func from(v: Int64): Value {
        VInteger(v)
    }
    static func from(v: String): Value {
        VString(v)
    }
    static func from(v: Bool): Value {
        VBoolean(v)
    }
    static func from(_: Unit): Value {
        VUnit
    }
    static func from(v: FuncValue): Value {
        VFunction(v)
    }
    static func from(v : MainValue): Value {
        VMain(v)
    }
}

public class FuncValue <: ToString{
    public var funcDecl: FuncDecl
    // public var type: FuncType

    public init(_funcDecl: FuncDecl) {
        this.funcDecl = _funcDecl
    }

    public override func toString(): String {
        "func"
    }
}

public class MainValue <: ToString{
    public var mainDecl: MainDecl

    public init(_mainDecl: MainDecl) {
        this.mainDecl = _mainDecl
    }

    public override func toString(): String {
        "main"
    }
}
