package cjcj.executor

import std.deriving.Derive

// This is a very simple representation of values in the interpreter.
// You may need to extend or modify it depending on your design.
// Depending on your design, you may even need to repackage it with another class.
@Derive[ToString]
public enum Value {
    | VInteger(Int64)
    | VString(String)
    | VBoolean(Bool)
    | VUnit

    public func toValueString(): String {
        match (this) {
            case VInteger(i) => return i.toString()
            case VString(s) => return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
            case VBoolean(b) => return b.toString()
            case VUnit => return "()"
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
}
