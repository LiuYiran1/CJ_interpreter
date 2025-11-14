package cjcj.parser

import cjcj.scanner.Token
import cjcj.scanner.TokenKind
import std.collection.*
import std.ast.Position
import std.env.ConsoleWriter

public class Reporter {
    private let console: ConsoleWriter
    private let errors: ArrayList<BaseErrorMessage> = ArrayList()

    public Reporter(console: ConsoleWriter, private let tokens: Array<Token>) {
        this.console = console
    }

    public func pop() {
        errors.remove(at: errors.size - 1)
    }

    public prop empty: Bool {
        get() {
            errors.isEmpty()
        }
    }

    private func getSuffixPrefix(current: Int64): (String, String) {
        var prefix: String = ""
        var suffix: String = ""
        for (i in max(current - 9, 0)..current) {
            if (tokens[i].pos.line == tokens[current].pos.line) {
                prefix += tokens[i].value + " "
            }
        }
        for (i in current + 1..min(current + 10, tokens.size)) {
            if (tokens[i].pos.line == tokens[current].pos.line) {
                suffix += tokens[i].value + " "
            }
        }
        //remove the first two characters of the line because it's a NL '\n'
        return (prefix.trimStart("\\n"), suffix)
    }

    func error(token: Token, message: String, index: Int64) {
        if (token.kind == TokenKind.END) {
            errors.add(Error(token.pos.line, index, "end", message, getSuffixPrefix(index)))
        } else {
            errors.add(Error(token.pos.line, index, token.value, message, getSuffixPrefix(index)))
        }
    }

    func consumeError(token: Token, index: Int64, expected: TokenKind, found: String) {
        if (token.kind == TokenKind.END) {
            errors.add(
                Error(token.pos.line, index, "end",
                    "expected '${redify(expected.toString())}', found '${redify(found.toString())}'",
                    getSuffixPrefix(index)))
        } else {
            errors.add(
                Error(token.pos.line, index, token.value,
                    "expected '${redify(expected.toString())}', found '${redify(found.toString())}'",
                    getSuffixPrefix(index)))
        }
    }

    func unclosedDelimiterError(currentToken: Token, startToken: Token, startIndex: Int64, currentIndex: Int64) {
        errors.add(
            ErrorUnclosedDelimiter(startToken.pos.line, startIndex, startToken.value, getSuffixPrefix(startIndex),
                currentToken.pos.line, currentIndex, currentToken.value, getSuffixPrefix(currentIndex),
                getEndToken(startToken.kind)))
    }

    public static func redify(str: String) {
        return "\u{001b}[31m${str}\u{001b}[0m"
    }

    public func logErrors() {
        if (errors.size > 0) {
            for (i in 0..(min(errors.size, 5))) {
                console.write(errors[i])
            }
            console.write(
                """

${errors.size} errors generated, ${min(errors.size, 5)} errors printed.
Failed to parse program.
""")
        }
    }
}

private func getEndToken(startKind: TokenKind): String {
    match (startKind) {
        case TokenKind.LPAREN => ")"
        case TokenKind.LCURL => "}"
        case TokenKind.LSQUARE => "]"
        case _ => throw Exception("Invalid start token kind for delimiter")
    }
}
