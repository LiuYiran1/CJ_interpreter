package cjcj.parser

import cjcj.visitor.*
import cjcj.scanner.Token
import cjcj.scanner.TokenKind
import cjcj.scanner.TokenKindHelper

public open class FinalError <: Exception {
    init(message: String) {
        super(message)
    }
    init() {}
}

public open class ConsumeError <: FinalError {
    init(message: String) {
        super(message)
    }
    init() {}
}

public open class ParseError <: FinalError {}

public abstract class NodeIdManager {
    // The ID 0 is a default invalid value.
    private static var count: Int64 = 1

    public static func nextId(): NodeId {
        let id = NodeId(count)
        count++
        id
    }
}

class ParserHelper {
    private var current_: Int64
    private let tokens: Array<Token>

    public ParserHelper(tokens: Array<Token>, private let reporter: Reporter) {
        this.tokens = tokens
        current_ = 0
    }

    /*
     * Tries to skip the NL token and check if the next token is of the target
     * kind.
     * If it is, advance and returns true.
     * If it's not it goes back to before the NL and returns false.
     */
    func skipNLCompare(target: Array<TokenKind>): Bool {
        let tmp: Int64 = current_
        skipNL()
        if (target.iterator().any({t => matches(t)})) {
            return true
        }
        current_ = tmp
        return false
    }

    func advance(): Token {
        if (!isAtEnd()) {
            current_++
        }
        previous()
    }

    func retreat(): Token {
        if (current_ > 0) {
            current_--
        }
        next()
    }

    func isAtEnd(): Bool {
        peek().kind == TokenKind.END
    }

    func peek(): Token {
        tokens[current_]
    }

    func matches(types: Array<TokenKind>): Bool {
        for (kind in types) {
            if (check(kind)) {
                advance()
                return true
            }
        }
        return false
    }

    func check(kind: Array<TokenKind>): Bool {
        if (isAtEnd()) {
            return false
        }
        kind.iterator().any({kind => peek().kind == kind})
    }

    func previous(): Token {
        tokens[current_ - 1]
    }

    func next(): Token {
        tokens[current_ + 1]
    }

    func skipNL(): Unit {
        if (check(TokenKind.NL)) {
            advance()
        }
    }

    /**
     * When we find an error we don't want to break everything and stop parsing.
     * So we synchronize, we discard tokens until we find a statement boundary.
     */
    func synchronize(): Unit {
        advance()

        while (!isAtEnd()) {
            // Finished a statement
            if (previous().kind == TokenKind.SEMI || previous().kind == TokenKind.NL) {
                return
            }

            if (peek().kind == TokenKind.CLASS || peek().kind == TokenKind.FUNC || peek().kind == TokenKind.VAR ||
                peek().kind == TokenKind.IF || peek().kind == TokenKind.WHILE || peek().kind == TokenKind.RETURN ||
                peek().kind == TokenKind.STRUCT || peek().kind == TokenKind.RPAREN) {
                return
            }
            advance()
        }
    }

    func synchronizeBlockParenthesis(start: Token, current: Int64): ?FinalError {
        var counter: Int64 = 1
        if (!check(TokenKind.LCURL) && !check(TokenKind.COMMA)) {
            do {
                if (peek().kind == TokenKind.LPAREN) {
                    counter++
                }
                if (peek().kind == TokenKind.RPAREN) {
                    counter--
                }
                advance()
            } while (!isAtEnd() && counter > 0 && !check(TokenKind.LCURL) && !check(TokenKind.COMMA))
        } else {
            reporter.pop()
        }
        if (isAtEnd()) {
            errorFinal(start, "unclosed delimiter: '('", current)
        } else if (check(TokenKind.LCURL) && counter > 0) {
            error(start, "unclosed delimiter: '('", current)
        } else if (check(TokenKind.COMMA)) {
            error(tokens[this.current - 1], "Malformed parameter", this.current - 1)
        } else {
            None
        }
    }

    func synchronizeBlockRightCurl(start: Token, current: Int64): ?FinalError {
        var counter: Int64 = 1
        if (!check(TokenKind.RCURL)) {
            do {
                if (peek().kind == TokenKind.LCURL) {
                    counter++
                }
                if (peek().kind == TokenKind.RCURL) {
                    counter--
                }
                advance()
            } while (!isAtEnd() && counter > 0)
        }
        if (isAtEnd()) {
            errorFinal(start, "unclosed delimiter: '{'", current)
        } else if (counter == 0) {
            return None
        } else {
            error(start, "unclosed delimiter: '{'", current)
        }
    }

    func synchronizeCallParenthesis(start: Token, current: Int64): Unit {
        var counter: Int64 = 1
        while (!isAtEnd() && counter > 0 && !check(TokenKind.NL)) {
            // Finished a statement
            if (check(TokenKind.LPAREN)) {
                counter++
            }
            if (check(TokenKind.RPAREN)) {
                counter--
            }
            advance()
        }
        if (isAtEnd()) {
            throw errorFinal(start, "unclosed delimiter: '\u{001b}[31m('\u{001b}[0m", current)
        } else {
            throw error(start, "unclosed delimiter: '\u{001b}[31m('\u{001b}[0m", current)
        }
    }

    public func pop() {
        reporter.pop()
    }

    func endStar(): Unit {
        while (matches(TokenKindHelper.END)) {}
    }

    func endPlus(_: String, _: Token, index: Int64): Unit {
        if (isAtEnd() || matches(TokenKindHelper.END)) {
            endStar()
        } else if (TokenKindHelper.TOP.iterator().any({tk => check(tk)})) {
            throw error(peek(), "Newline or semi expected before top level declaration", index)
        } else {
            throw error(peek(), "Expected newline, found '${peek().value}'", index)
        }
    }

    func error(token: Token, message: String, index: Int64): ParseError {
        reporter.error(token, message, index)
        ParseError()
    }

    func errorFinal(token: Token, message: String, index: Int64): FinalError {
        reporter.error(token, message, index)
        FinalError()
    }

    func consumeError(token: Token, index: Int64, expected: TokenKind, found: String) {
        reporter.consumeError(token, index, expected, found)
        ConsumeError()
    }

    // func unclosedDelimiterError(currentToken: Token, startToken: Token, index: Int64) {
    //     reporter.unclosedDelimiterError(currentToken, startToken, index)
    // }

    func logErrors() {
        reporter.logErrors()
    }

    func consume(kind: TokenKind, _: String, index: Int64): Token {
        if (check(kind)) {
            return advance()
        }

        throw consumeError(peek(), index, kind, peek().value)
    }

    /*
     * Tries to evaluate the function that is passed, if it cannot get
     * a valid result it'll go back to the token point it was before.
     */
    func tryParse<T>(fun: () -> ?T): ?T {
        let tmp: Int64 = current_
        if (let Some(val) <- fun()) {
            return val
        }
        current_ = tmp
        None
    }

    public prop current: Int64 {
        get() {
            current_
        }
    }
}
