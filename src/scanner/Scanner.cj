package cjcj.scanner

import std.collection.*
import std.ast.Position
import std.env.*

public class Scanner {
    private let source: Array<Rune>

    private let tokens: ArrayList<Token> = ArrayList<Token>()

    private var start = 0
    private var current = 0
    private var line: Int32 = 1
    private var column: Int32 = 1

    private static let keywords = HashMap<String, TokenKind>()

    public init(source: Array<Rune>) {
        this.source = source

        keywords["is"] = TokenKind.IS
        keywords["as"] = TokenKind.AS

        keywords["Int8"] = TokenKind.INT8
        keywords["Int16"] = TokenKind.INT16
        keywords["Int32"] = TokenKind.INT32
        keywords["Int64"] = TokenKind.INT64
        keywords["IntNative"] = TokenKind.INTNATIVE

        keywords["UInt8"] = TokenKind.UINT8
        keywords["UInt16"] = TokenKind.UINT16
        keywords["UInt32"] = TokenKind.UINT32
        keywords["UInt64"] = TokenKind.UINT64
        keywords["UIntNative"] = TokenKind.UINTNATIVE

        keywords["Float16"] = TokenKind.FLOAT16
        keywords["Float32"] = TokenKind.FLOAT32
        keywords["Float64"] = TokenKind.FLOAT64

        keywords["Rune"] = TokenKind.RUNE
        keywords["Bool"] = TokenKind.BOOLEAN
        keywords["Nothing"] = TokenKind.NOTHING
        keywords["Unit"] = TokenKind.UNIT

        keywords["struct"] = TokenKind.STRUCT
        keywords["enum"] = TokenKind.ENUM
        keywords["VArray"] = TokenKind.VARRAY
        keywords["This"] = TokenKind.THISTYPE

        keywords["interface"] = TokenKind.INTERFACE
        keywords["class"] = TokenKind.CLASS
        keywords["func"] = TokenKind.FUNC
        keywords["let"] = TokenKind.LET
        keywords["var"] = TokenKind.VAR
        keywords["const"] = TokenKind.CONST
        keywords["type"] = TokenKind.TYPE
        keywords["init"] = TokenKind.INIT

        keywords["this"] = TokenKind.THIS
        keywords["super"] = TokenKind.SUPER
        keywords["if"] = TokenKind.IF
        keywords["else"] = TokenKind.ELSE
        keywords["do"] = TokenKind.DO
        keywords["while"] = TokenKind.WHILE
        keywords["return"] = TokenKind.RETURN
        keywords["continue"] = TokenKind.CONTINUE
        keywords["break"] = TokenKind.BREAK
        // keywords["match"] = TokenKind.MATCH  // ADD WHEN WE INCLUDE ENUMS

        keywords["prop"] = TokenKind.PROP
        keywords["static"] = TokenKind.STATIC
        keywords["public"] = TokenKind.PUBLIC
        keywords["private"] = TokenKind.PRIVATE
        keywords["internal"] = TokenKind.INTERNAL
        keywords["protected"] = TokenKind.PROTECTED
        keywords["override"] = TokenKind.OVERRIDE
        keywords["abstract"] = TokenKind.ABSTRACT
        keywords["sealed"] = TokenKind.SEALED
        keywords["open"] = TokenKind.OPEN
        keywords["inout"] = TokenKind.INOUT
        keywords["mut"] = TokenKind.MUT
        keywords["operator"] = TokenKind.OPERATOR
        keywords["main"] = TokenKind.MAIN
        keywords["true"] = TokenKind.BOOL_LITERAL
        keywords["false"] = TokenKind.BOOL_LITERAL
    }

    public func scanTokens() {
        while (!isAtEnd()) {
            start = current
            scanToken()
        }
        tokens.add(Token(TokenKind.END, "END", Position(0, line, column)))
        tokens
    }

    private func scanToken() {
        let c: Rune = advance()
        match (c) {
            case '(' => addToken(if (matches(r')')) {
                TokenKind.UNIT_LITERAL
            } else {
                TokenKind.LPAREN
            })

            case ')' => addToken(TokenKind.RPAREN)
            case '{' => addToken(TokenKind.LCURL)
            case '}' => addToken(TokenKind.RCURL)
            case '[' => addToken(TokenKind.LSQUARE)
            case ']' => addToken(TokenKind.RSQUARE)
            case ',' => addToken(TokenKind.COMMA)
            case '.' => addToken(TokenKind.DOT)

            case ';' =>
                addToken(TokenKind.SEMI)
                if (matches(r'\n')) {}

            case '^' => addToken(TokenKind.BITXOR)
            case '~' => addToken(TokenKind.BITNOT)
            case ':' => addToken(TokenKind.COLON)
            case '#' => addToken(TokenKind.HASH)
            case '?' => addToken(TokenKind.QUEST)
            case '_' =>
                if (isAlpha(peekNext())) {
                    identifier()
                } else {
                    addToken(TokenKind.WILDCARD)
                }
            case 'r' =>
                if (matches(r'\'')) {
                    advance()
                    if (!matches(r'\'')) {
                        println("Line: ${line} , Unterminated byte rune literal.")
                    }
                    addToken(TokenKind.RUNE_LITERAL)
                } else {
                    identifier()
                }

            case 'b' =>
                if (matches(r'\'')) {
                    advance()
                    if (!matches(r'\'')) {
                        println("Line: ${line} , Unterminated byte rune literal.")
                    }
                    addToken(TokenKind.RUNE_BYTE_LITERAL, advance())
                } else {
                    identifier()
                }

            case '%' => addToken(if (matches(r'=')) {
                TokenKind.MOD_ASSIGN
            } else {
                TokenKind.MOD
            })

            case '/' =>
                if (matches(r'/')) {
                    if (windowsiness()) {
                        while (peek() != r'\r' && peekNext() != r'\n' && !isAtEnd()) {
                            advance()
                        }
                    } else {
                        while (peek() != r'\n' && !isAtEnd()) {
                            advance()
                        }
                    }
                } else if (matches(r'*')) {
                    cStyleComment()
                    return
                } else {
                    addToken(if (matches(r'=')) {
                        TokenKind.DIV_ASSIGN
                    } else {
                        TokenKind.DIV
                    })
                }

            case '-' => addToken(if (matches(r'-')) {
                TokenKind.DECR
            } else if (matches(r'>')) {
                TokenKind.ARROW
            } else if (matches(r'=')) {
                TokenKind.SUB_ASSIGN
            } else {
                TokenKind.SUB
            })

            case '+' => addToken(if (matches(r'+')) {
                TokenKind.INCR
            } else if (matches(r'=')) {
                TokenKind.ADD_ASSIGN
            } else {
                TokenKind.ADD
            })

            case '*' => addToken(if (matches(r'*')) {
                TokenKind.EXP
            } else if (matches(r'=')) {
                TokenKind.MUL_ASSIGN
            } else {
                TokenKind.MUL
            })

            case '&' => addToken(if (matches(r'&')) {
                TokenKind.AND
            } else {
                TokenKind.BITAND
            })

            case '|' => addToken(if (matches(r'|')) {
                TokenKind.OR
            } else {
                TokenKind.BITOR
            })

            case '!' => addToken(if (matches(r'=')) {
                TokenKind.NOTEQ
            } else {
                TokenKind.NOT
            })

            case '>' => addToken(if (matches(r'=')) {
                TokenKind.GE
            } else if (matches(r'>')) {
                TokenKind.RSHIFT
            } else {
                TokenKind.GT
            })

            case '<' => addToken(
                if (matches(r'=')) {
                    TokenKind.LE
                } else if (matches(r':')) {
                    TokenKind.UPPERBOUND
                } else if (matches(r'-')) {
                    TokenKind.BACKARROW
                } else if (matches(r'<')) {
                    TokenKind.LSHIFT
                } else {
                    TokenKind.LT
                })

            case '=' => addToken(if (matches(r'=')) {
                TokenKind.EQUAL
            } else if (matches(r'>')) {
                TokenKind.DOUBLE_ARROW
            } else {
                TokenKind.ASSIGN
            })

            case '\n' =>
                if (!windowsiness()) {
                    line++
                    column = 1
                    skipSpace()
                    while (!isAtEnd() && matches(r'\n')) {
                        line++
                        column = 1
                        skipSpace()
                    }
                }
                addToken(TokenKind.NL, "\\n".toRuneArray())
                return

            case '\r' =>
                if (windowsiness() && matches(r'\n')) {
                    line++
                    column = 1
                    skipSpace()
                    while (!isAtEnd() && matches(r'\r') && matches(r'\n')) {
                        line++
                        column = 1
                        skipSpace()
                    }
                }
                addToken(TokenKind.NL, "\\n".toRuneArray())
                return

            case ' ' => return

            case '"' => string() // TO BE IMPLEMENTED

            case _ =>
                if (isDigit(c)) {
                    number()
                } else if (isAlpha(c)) {
                    identifier()
                } else {
                    println("Line: ${line}: Error Unexpected character: ${source[current]}")
                }
        }
    }

    private func cStyleComment() {
        var counter = 1
        while (!isAtEnd() && counter > 0) {
            if (peek() == r'\n') {
                line++
                column = 1
            } else if (peek() == r'/' && peekNext() == r'*') {
                counter++
                advance()
            } else if (peek() == r'*' && peekNext() == r'/') {
                counter--
                advance()
            }
            advance()
        }

        if (isAtEnd() && counter > 0) {
            println("Unterminated cStyle Comment")
            exit(65)
        }

        // Remove the following comment if you need a comment token.
        // let value = source[start+2..current-2]
        // addToken(TokenKind.COMMENT, value)
    }

    private func string() {
        var value: String = ""

        while (peek() != r'"' && !isAtEnd()) {
            if (peek() == r'\\' && peekNext() == r'"') {
                advance()
            }
            value += advance().toString()
        }

        if (isAtEnd()) {
            println("Line: ${line} , Unterminated String.")
            exit(65)
            return
        }
        advance()

        addToken(TokenKind.STRING_LITERAL, value.toRuneArray())
    }

    private func number() {
        while (isDigit(peek())) {
            advance()
        }

        if (peek() == r'.' && isDigit(peekNext())) {
            // Consume the "."
            advance()
            while (isDigit(peek())) {
                advance()
            }
            addToken(TokenKind.FLOAT_LITERAL, source[start..current])
            return
        }
        addToken(TokenKind.INTEGER_LITERAL, source[start..current])
    }

    private func identifier() {
        while (isAlphaNumeric(peek())) {
            advance()
        }
        let text: Array<Rune> = source[start..current]
        var typ: Option<TokenKind> = keywords.get(String(text))

        if (typ.isNone()) {
            typ = TokenKind.IDENTIFIER
        }
        addToken(typ.getOrThrow(), text)
    }

    private func matches(expected: Rune) {
        if (isAtEnd()) {
            return false
        }
        if (source[current] != expected) {
            return false
        }
        current++
        column++
        return true
    }

    private func peek(): Rune {
        if (isAtEnd()) {
            return r'\0'
        }
        return source[current]
    }

    private func peekNext(): Rune {
        if (current + 1 >= source.size) {
            return r'\0'
        }
        return source[current + 1]
    }

    private func isAlphaNumeric(c: Rune) {
        return isAlpha(c) || isDigit(c)
    }

    private func isDigit(c: Rune): Bool {
        return c >= r'0' && c <= r'9'
    }

    private func isAlpha(c: Rune) {
        return ((c >= r'a' && c <= r'z') || (c >= r'A' && c <= r'Z') || c == r'_')
    }

    private func isAtEnd(): Bool {
        current >= source.size
    }

    private func advance(): Rune {
        let charToReturn = source[current]
        current++
        column++
        return charToReturn
    }

    private func skipSpace() {
        while (matches(r' ')) {}
    }

    private func addToken(typ: TokenKind) {
        let text = source[start..current]
        addToken(typ, text)
    }

    private func addToken(typ: TokenKind, value: Array<Rune>) {
        tokens.add(Token(typ, String(value), Position(0, line, column)))
    }
}

@When[os == "Windows"]
func windowsiness() {
    return true
}

@When[os != "Windows"]
func windowsiness() {
    return false
}
