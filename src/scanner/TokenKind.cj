package cjcj.scanner

import std.deriving.*

@Derive[Equatable]
public enum TokenKind <: ToString {
    DOT
    | /*  "."           */
        COMMA
    | /*  ","           */
        LPAREN
    | /*  "("           */
        RPAREN
    | /*  ")"           */
        LSQUARE
    | /*  "["           */
        RSQUARE
    | /*  "]"           */
        LCURL
    | /*  "{"           */
        RCURL
    | /*  "}"           */
        EXP
    | /*  "**"          */
        MUL
    | /*  "*"           */
        MOD
    | /*  "%"           */
        DIV
    | /*  "/"           */
        ADD
    | /*  "+"           */
        SUB
    | /*  "-"           */
        INCR
    | /*  "++"          */
        DECR
    | /*  "--"          */
        AND
    | /*  "&&"          */
        OR
    | /*  "||"          */
        NOT
    | /*  "!"           */
        BITAND
    | /*  "&"           */
        BITOR
    | /*  "|"           */
        BITXOR
    | /*  "^"           */
        BITNOT
    | /*  "~"           */
        LSHIFT
    | /*  "<<"          */
        RSHIFT
    | /*  ">>"          */
        COLON
    | /*  ":"           */
        SEMI
    | /*  ";"           */
        ASSIGN
    | /*  "="           */
        ADD_ASSIGN
    | /*  "+="          */
        SUB_ASSIGN
    | /*  "-="          */
        MUL_ASSIGN
    | /*  "*="          */
        DIV_ASSIGN
    | /*  "/="          */
        MOD_ASSIGN
    | /*  "%="          */
        BACKARROW
    | /*  "<-"          */
        DOUBLE_ARROW
    | /*  "=>"          */
        HASH
    | /*  "#"           */
        QUEST
    | /*  "?"           */
        LT
    | /*  "<"           */
        GT
    | /*  ">"           */
        LE
    | /*  "<="          */
        GE
    | /*  ">="          */
        IS
    | /*  "is"          */
        AS
    | /*  "as"          */
        NOTEQ
    | /*  "!="          */
        EQUAL
    | /*  "=="          */
        WILDCARD
    | /*  "_"           */
        INT8
    | /*  "Int8"        */
        INT16
    | /*  "Int16"       */
        INT32
    | /*  "Int32"       */
        INT64
    | /*  "Int64"       */
        INTNATIVE
    | /*  "IntNative"   */
        UINT8
    | /*  "UInt8"       */
        UINT16
    | /*  "UInt16"      */
        UINT32
    | /*  "UInt32"      */
        UINT64
    | /*  "UInt64"      */
        UINTNATIVE
    | /*  "UIntNative"  */
        FLOAT16
    | /*  "Float16"     */
        FLOAT32
    | /*  "Float32"     */
        FLOAT64
    | /*  "Float64"     */
        RUNE
    | /*  "Rune"        */
        BOOLEAN
    | /*  "Bool"        */
        NOTHING
    | /*  "Nothing"     */
        UNIT
    | /*  "Unit"        */
        STRUCT
    | /*  "struct"      */
        ENUM
    | /*  "enum"        */
        VARRAY
    | /*  "VArray"      */
        THISTYPE
    | /*  "This"        */
        CLASS
    | /*  "class"       */
        INTERFACE
    | /* e.g. "interface" */
        FUNC
    | /*  "func"        */
        LET
    | /*  "let"         */
        VAR
    | /*  "var"         */
        CONST
    | /*  "const"       */
        TYPE
    | /*  "type"        */
        INIT
    | /*  "init"        */
        THIS
    | /*  "this"        */
        SUPER
    | /*  "super"       */
        IF
    | /*  "if"          */
        ELSE
    | /*  "else"        */
        DO
    | /*  "do"          */
        WHILE
    | /*  "while"       */
        RETURN
    | /*  "return"      */
        CONTINUE
    | /*  "continue"    */
        BREAK
    | /*  "break"       */
        MATCH
    | /*  "match"       */
        PROP
    | /*  "prop"        */
        STATIC
    | /*  "static"      */
        PUBLIC
    | /*  "public"      */
        PRIVATE
    | /*  "private"     */
        INTERNAL
    | /*  "internal"     */
        PROTECTED
    | /*  "protected"   */
        OVERRIDE
    | /*  "override"    */
        ABSTRACT
    | /*  "abstract"    */
        SEALED
    | /*  "sealed"      */
        OPEN
    | /*  "open"        */
        INOUT
    | /*  "inout"       */
        MUT
    | /*  "mut"         */
        OPERATOR
    | /*  "operator"    */
        UPPERBOUND
    | /*  "<:"          */
        MAIN
    | /*  "main"        */
        IDENTIFIER
    | /*  "x"           */
        INTEGER_LITERAL
    | /*  e.g. "1"      */
        RUNE_BYTE_LITERAL
    | /*  e.g. "b'x'"   */
        FLOAT_LITERAL
    | /*  e.g. "'1.0'"  */
        COMMENT
    | /*  e.g. "/*xx*/" */
        NL
    | /*  newline         */
        END
    | /*  end of file     */
        RUNE_LITERAL
    | /*  e.g. "r'x'"       */
        STRING_LITERAL
    | /*  e.g. ""xx""     */

        //     SINGLE_QUOTED_STRING_LITERAL
        // | /*  e.g. "'xx'"     */
        //     MULTILINE_STRING
        // | /*  e.g. """"aaa""""   */
        //     MULTILINE_RAW_STRING
        // | /*  e.g. "#"aaa"#"     */

        BOOL_LITERAL
    | /*  "true" or "false"  */
        UNIT_LITERAL
    | /*  "()"               */
        ARROW
    | /*  "->"               */
        ILLEGAL

    public func toString(): String {
        return match (this) {
            case DOT => "."
            case COMMA => ","
            case LPAREN => "("
            case RPAREN => ")"
            case LSQUARE => "["
            case RSQUARE => "]"
            case LCURL => "{"
            case RCURL => "}"
            case EXP => "**"
            case MUL => "*"
            case MOD => "%"
            case DIV => "/"
            case ADD => "+"
            case SUB => "-"
            case INCR => "++"
            case DECR => "--"
            case AND => "&&"
            case OR => "||"
            case NOT => "!"
            case BITAND => "&"
            case BITOR => "|"
            case BITXOR => "^"
            case BITNOT => "~"
            case LSHIFT => "<<"
            case RSHIFT => ">>"
            case COLON => ":"
            case SEMI => ";"
            case ASSIGN => "="
            case ADD_ASSIGN => "+="
            case SUB_ASSIGN => "-="
            case MUL_ASSIGN => "*="
            case DIV_ASSIGN => "/="
            case MOD_ASSIGN => "%="
            case BACKARROW => "<-"
            case DOUBLE_ARROW => "=>"
            case HASH => "#"
            case QUEST => "?"
            case LT => "<"
            case GT => ">"
            case LE => "<="
            case GE => ">="
            case IS => "is"
            case AS => "as"
            case NOTEQ => "!="
            case EQUAL => "=="
            case WILDCARD => "_"
            case INT8 => "Int8"
            case INT16 => "Int16"
            case INT32 => "Int32"
            case INT64 => "Int64"
            case INTNATIVE => "IntNative"
            case UINT8 => "UInt8"
            case UINT16 => "UInt16"
            case UINT32 => "UInt32"
            case UINT64 => "UInt64"
            case UINTNATIVE => "UIntNative"
            case FLOAT16 => "Float16"
            case FLOAT32 => "Float32"
            case FLOAT64 => "Float64"
            case RUNE => "Rune"
            case BOOLEAN => "Bool"
            case NOTHING => "Nothing"
            case UNIT => "Unit"
            case STRUCT => "struct"
            case ENUM => "enum"
            case VARRAY => "VArray"
            case THISTYPE => "This"
            case CLASS => "class"
            case INTERFACE => "interface"
            case FUNC => "func"
            case LET => "let"
            case VAR => "var"
            case CONST => "const"
            case TYPE => "type"
            case INIT => "init"
            case THIS => "this"
            case SUPER => "super"
            case IF => "if"
            case ELSE => "else"
            case DO => "do"
            case WHILE => "while"
            case RETURN => "return"
            case CONTINUE => "continue"
            case BREAK => "break"
            case MATCH => "match"
            case PROP => "prop"
            case STATIC => "static"
            case PUBLIC => "public"
            case PRIVATE => "private"
            case INTERNAL => "internal"
            case PROTECTED => "protected"
            case OVERRIDE => "override"
            case ABSTRACT => "abstract"
            case SEALED => "sealed"
            case OPEN => "open"
            case INOUT => "inout"
            case MUT => "mut"
            case OPERATOR => "operator"
            case UPPERBOUND => "<:"
            case MAIN => "main"
            case IDENTIFIER => "identifier"
            case INTEGER_LITERAL => "integer literal"
            case RUNE_BYTE_LITERAL => "rune byte literal"
            case FLOAT_LITERAL => "float literal"
            case COMMENT => "comment"
            case NL => "newline"
            case END => "end of file"
            case RUNE_LITERAL => "rune literal"
            case STRING_LITERAL => "string literal"
            case BOOL_LITERAL => "boolean literal"
            case UNIT_LITERAL => "unit literal"
            case ARROW => "->"
            case ILLEGAL => "illegal"
        }
    }
}

public class TokenKindHelper {
    public static let PRIMITIVE_TYPE_TOKEN_KIND: Array<TokenKind> = [
        INT8,
        INT16,
        INT32,
        INT64,
        INTNATIVE,
        UINT8,
        UINT16,
        UINT32,
        UINT64,
        UINTNATIVE,
        FLOAT16,
        FLOAT32,
        FLOAT64,
        RUNE,
        BOOLEAN,
        NOTHING,
        UNIT
    ]

    public static let MODIFIERS_TOKEN_KIND: Array<TokenKind> = [
        PROP,
        STATIC,
        PUBLIC,
        PRIVATE,
        INTERNAL,
        PROTECTED,
        OVERRIDE,
        ABSTRACT,
        SEALED,
        OPEN,
        INOUT,
        MUT,
        CONST
    ]

    public static let CLASS_MODIFIERS_TOKEN_KIND: Array<TokenKind> = [
        PUBLIC,
        PRIVATE,
        INTERNAL,
        PROTECTED,
        ABSTRACT,
        OPEN
    ]

    public static let FUNCTION_MODIFIERS_TOKEN_KIND: Array<TokenKind> = [
        PUBLIC,
        PRIVATE,
        PROTECTED,
        INTERNAL,
        STATIC,
        OPEN,
        MUT,
        CONST
    ]

    public static let VAR_MODIFIERS_TOKEN_KIND: Array<TokenKind> = [
        PUBLIC,
        PRIVATE,
        PROTECTED,
        INTERNAL,
        STATIC
    ]

    public static let STRUCT_MODIFIERS_TOKEN_KIND: Array<TokenKind> = [
        PUBLIC,
        PRIVATE,
        PROTECTED,
        INTERNAL
    ]

    public static let ASSIGNMENT_OPERATOR: Array<TokenKind> = [TokenKind.ASSIGN]

    public static let COMPARISON_OPERATOR: Array<TokenKind> = [
        TokenKind.LT,
        TokenKind.GT,
        TokenKind.LE,
        TokenKind.GE
    ]

    public static let EQUALITY_OPERATOR: Array<TokenKind> = [
        TokenKind.NOTEQ,
        TokenKind.EQUAL
    ]

    public static let ADDITIVE_OPERATOR: Array<TokenKind> = [
        TokenKind.ADD,
        TokenKind.SUB
    ]

    public static let EXPONENT_OPERATOR: Array<TokenKind> = [TokenKind.EXP]

    public static let MULTIPLICATIVE_OPERATOR: Array<TokenKind> = [
        TokenKind.MOD,
        TokenKind.DIV,
        TokenKind.MUL
    ]

    public static let PREFIX_UNARY_OPERATOR: Array<TokenKind> = [
        TokenKind.SUB,
        TokenKind.NOT
    ]

    public static let THIS_SUPER: Array<TokenKind> = [
        TokenKind.THIS,
        TokenKind.SUPER
    ]

    public static let NUMERIC_TYPES: Array<TokenKind> = [
        TokenKind.INT8,
        TokenKind.INT16,
        TokenKind.INT32,
        TokenKind.INT64,
        TokenKind.INTNATIVE,
        TokenKind.UINT8,
        TokenKind.UINT16,
        TokenKind.UINT32,
        TokenKind.UINT64,
        TokenKind.UINTNATIVE,
        TokenKind.FLOAT16,
        TokenKind.FLOAT32,
        TokenKind.FLOAT64
    ]

    public static let CHAR_LANG_TYPES: Array<TokenKind> = NUMERIC_TYPES.concat(
        [
            TokenKind.RUNE,
            TokenKind.BOOLEAN,
            TokenKind.NOTHING,
            TokenKind.UNIT,
            TokenKind.THISTYPE
        ]
    )

    public static let LITERAL_CONSTANT: Array<TokenKind> = [
        TokenKind.BOOL_LITERAL,
        TokenKind.RUNE_BYTE_LITERAL,
        TokenKind.INTEGER_LITERAL,
        TokenKind.STRING_LITERAL,
        TokenKind.FLOAT_LITERAL,
        TokenKind.RUNE_LITERAL,
        TokenKind.UNIT_LITERAL
    ]

    public static let END: Array<TokenKind> = [
        TokenKind.NL,
        TokenKind.SEMI
    ]

    public static let TOP: Array<TokenKind> = [
        TokenKind.MAIN,
        TokenKind.FUNC,
        TokenKind.LET,
        TokenKind.VAR,
        TokenKind.CLASS,
        TokenKind.INTERFACE
    ]
}
