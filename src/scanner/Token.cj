package cjcj.scanner

import std.ast.Position

public class Token <: ToString {
    public let kind: TokenKind
    public let value: String
    public let pos: Position

    public init(typ: TokenKind, value: String, pos: Position) {
        this.kind = typ
        this.value = value
        this.pos = pos
    }

    public init() {
        this.kind = TokenKind.ILLEGAL
        this.value = ""
        this.pos = Position()
    }

    public func toString(): String {
        return "${kind} ${value} "
    }
}
