package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.*

class Lab1TodoException <: Exception {
    public init(message: String) {
        super("Lab 1 TODO: " + message)
    }
}

class UnhandledTokenKind <: Exception {
    public init(message: String) {
        super("Unhandled Token Kind: " + message)
    }
}

/** 
 * Evaluator Visitor
 *
 * Lab1 TODO: We have given the simplest form, each `Node` will return a `Value` after evaluation.
 * But is this sufficient? Do you need to add something new to handle ASTs that don't return a value?
 *
 * You may need to modify the member variables and/or generic parameters of the Evaluator class.
 */
public open class Evaluator <: Visitor<Value> {
    // How do you get and set the context when executing an expression?
    // You might need to add some member variables to do this.
    //
    // private let context = ...
    // private let static_scope = ...
    let recordsStack = ArrayStack<ActivationRecords>()
    var curRecords: ?ActivationRecords = None

    public open override func visit(_: Program): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Program")
    }

    // This is just an example of how to implement the visit method for BinaryExpr.
    // You may need to modify, split, or completely rewrite it depending on your design.

    private func getTypeMisErrorCode(op: TokenKind): ErrorCode {
        match (op) {
            case TokenKind.ADD => return ErrorCode.ADD_TYPE_MISMATCH;
            case TokenKind.SUB => return ErrorCode.SUB_TYPE_MISMATCH;
            case TokenKind.MUL => return ErrorCode.MUL_TYPE_MISMATCH;
            case TokenKind.DIV => return ErrorCode.DIV_TYPE_MISMATCH;
            case TokenKind.MOD => return ErrorCode.MOD_TYPE_MISMATCH;
            case TokenKind.EXP => return ErrorCode.EXP_TYPE_MISMATCH;
            case TokenKind.GT | TokenKind.GE | TokenKind.LT | TokenKind.LE => return ErrorCode.CMP_TYPE_MISMATCH
            case TokenKind.EQUAL => return ErrorCode.EQ_TYPE_MISMATCH;
            case TokenKind.NOTEQ => return ErrorCode.NEQ_TYPE_MISMATCH;
            case TokenKind.AND => return ErrorCode.AND_TYPE_MISMATCH;
            case TokenKind.OR => return ErrorCode.OR_TYPE_MISMATCH;
            case _ => throw UnhandledTokenKind("in getTypeMisErrorCode");
        }
    }

    private func calcIntConstInt(a: Int64, b: Int64, op: TokenKind, node: Node): Int64 {
        let max = Int64.Max
        let min = Int64.Min

        match (op) {
            case TokenKind.ADD =>
                if ((b > 0 && a > max - b) || (b < 0 && a < min - b)) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.ADD_OVERFLOW,
                        "整数加法结果超出 `Int64` 表示范围",
                        node
                    )
                }
                return a + b

            case TokenKind.SUB =>
                if ((b < 0 && a > max + b) || (b > 0 && a < min + b)) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.SUB_OVERFLOW,
                        "整数减法结果超出 `Int64` 表示范围",
                        node
                    )
                }
                return a - b

            case TokenKind.MUL =>
                // 零乘任意数都安全
                if (a != 0 && (a == -1 && b == min || b == -1 && a == min || a > max / b || a < min / b)) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.MUL_OVERFLOW,
                        "整数乘法结果超出 `Int64` 表示范围",
                        node
                    )
                }
                return a * b

            case TokenKind.DIV =>
                // 检查除零
                if (b == 0) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.DIV_BY_ZERO,
                        "整数除法除数不能为 0",
                        node
                    )
                }
                return a / b

            case TokenKind.MOD =>
                if (b == 0) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.MOD_BY_ZERO,
                        "取模运算除数不能为 0",
                        node
                    )
                }
                return a % b

            case TokenKind.EXP =>
                if (b < 0) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.EXP_NEGATIVE_POWER,
                        "指数为负数的幂运算不被支持",
                        node
                    )
                }
                var result: Int64 = 1
                var base = a
                var exponent = b
                while (exponent > 0) {
                    if (exponent % 2 == 1) {
                        if (result != 0 && (result > max / base || result < min / base)) {
                            throw CjcjRuntimeErrorWithLocation(
                                ErrorCode.EXP_OVERFLOW,
                                "幂运算结果超出 `Int64` 表示范围",
                                node
                            )
                        }
                        result *= base
                    }
                    exponent = exponent / 2
                    if (exponent > 0) {
                        if (base != 0 && (base > max / base || base < min / base)) {
                            throw CjcjRuntimeErrorWithLocation(
                                ErrorCode.EXP_OVERFLOW,
                                "幂运算结果超出 `Int64` 表示范围",
                                node
                            )
                        }
                        base *= base
                    }
                }
                return result

            case _ => throw UnhandledTokenKind("Unhandled binary int int int");
        }
    }

    private func calcIntConstBool(a: Int64, b: Int64, op: TokenKind, node: Node): Bool {
        match (op) {
            case TokenKind.LT => return a < b
            case TokenKind.LE => return a <= b
            case TokenKind.GT => return a > b
            case TokenKind.GE => return a >= b
            case TokenKind.EQUAL => return a == b
            case TokenKind.NOTEQ => return a != b
            case _ => throw UnhandledTokenKind("Unhandled binary int int bool");
        }
    }

    private func calcStringConstBool(a: String, b: String, op: TokenKind, node: Node): Bool {
        match (op) {
            case TokenKind.LT => return a < b // 字典序
            case TokenKind.LE => return a <= b
            case TokenKind.GT => return a > b
            case TokenKind.GE => return a >= b
            case TokenKind.EQUAL => return a == b
            case TokenKind.NOTEQ => return a != b
            case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.CMP_TYPE_MISMATCH, "字符串比较操作符不匹配", node)
        }
    }

    private func calcBoolConstBool(a: Bool, b: Bool, op: TokenKind, node: Node): Bool {
        match (op) {
            case TokenKind.AND => return a && b // 短路在外层逻辑处理
            case TokenKind.OR => return a || b
            case TokenKind.EQUAL => return a == b
            case TokenKind.NOTEQ => return a != b
            case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.AND_TYPE_MISMATCH, "布尔运算操作符不匹配", node)
        }
    }

    private func calcStrIntConstString(a: String, b: Int64, op: TokenKind, node: Node): String {
        return a * b;
    }

    private func calcStringConstString(a: String, b: String, op: TokenKind, node: Node): String {
        match (op) {
            case TokenKind.ADD => return a + b;
            case _ => throw UnhandledTokenKind("Unhandled binary str str str");
        }
    }

    public open override func visit(expr: BinaryExpr): Value {
        let left = expr.left.traverse(this)
        // && || 短路
        match (expr.oper.kind) {
            case TokenKind.AND => match (left) {
                case VBoolean(b) =>
                    if (!b) {
                        return Value.from(false)
                    }
                case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                    "cannot op left = ${left}", expr)
            }
            case TokenKind.OR => match (left) {
                case VBoolean(b) =>
                    if (b) {
                        return Value.from(true)
                    }
                case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                    "cannot op left = ${left}", expr)
            }
            case _ => ()
        }
        let right = expr.right.traverse(this)
        try {
            match (expr.oper.kind) {
                case TokenKind.ADD => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => return Value.from(calcIntConstInt(a, b, expr.oper.kind, expr))
                    case (VString(a), VString(b)) => return Value.from(calcStringConstString(a, b, expr.oper.kind, expr))
                    case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                        "cannot op left = ${left}, right = ${right}", expr)
                }
                case TokenKind.SUB | TokenKind.DIV | TokenKind.MOD | TokenKind.EXP => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => return Value.from(calcIntConstInt(a, b, expr.oper.kind, expr))
                    case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                        "cannot op left = ${left}, right = ${right}", expr)
                }
                case TokenKind.MUL => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => return Value.from(calcIntConstInt(a, b, expr.oper.kind, expr))
                    case (VString(a), VInteger(b)) => return Value.from(calcStrIntConstString(a, b, expr.oper.kind, expr))
                    case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                        "cannot op left = ${left}, right = ${right}", expr)
                }
                case TokenKind.GT | TokenKind.GE | TokenKind.LT | TokenKind.LE => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => return Value.from(calcIntConstBool(a, b, expr.oper.kind, expr))
                    case (VString(a), VString(b)) => return Value.from((calcStringConstBool(a, b, expr.oper.kind, expr)))
                    case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                        "cannot op left = ${left}, right = ${right}", expr)
                }
                case TokenKind.EQUAL | TokenKind.NOTEQ => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => return Value.from(calcIntConstBool(a, b, expr.oper.kind, expr))
                    case (VString(a), VString(b)) => return Value.from(calcStringConstBool(a, b, expr.oper.kind, expr))
                    case (VBoolean(a), VBoolean(b)) => return Value.from(calcBoolConstBool(a, b, expr.oper.kind, expr))
                    case (VUnit, Vunit) => return Value.from(true);
                    case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                        "cannot op left = ${left}, right = ${right}", expr)
                }
                case TokenKind.AND | TokenKind.OR => match ((left, right)) {
                    case (VBoolean(a), VBoolean(b)) => return Value.from(calcBoolConstBool(a, b, expr.oper.kind, expr))
                    case _ => throw CjcjRuntimeErrorWithLocation(getTypeMisErrorCode(expr.oper.kind),
                        "cannot op left = ${left}, right = ${right}", expr)
                }
                case _ => throw UnhandledTokenKind("Unimplemented Binary Operator `${expr.oper.kind}`")
            }
        } catch (e: OverflowException) {
            match (e.message) {
                case "add" => throw CjcjRuntimeErrorWithLocation(ErrorCode.ADD_OVERFLOW,
                    "overflow add: left = ${left}, right = ${right}", expr)
                case _ => throw Exception("You need to handle overflow of ${e.message}")
            }
        }
    }

    public open override func visit(expr: UnaryExpr): Value {
        // 这里要对INT_MIN取负做出特殊处理
        match (expr.right) {
            case exp: LitConstExpr => if(expr.oper.kind == TokenKind.SUB && exp.literal.value == "9223372036854775808"){
                        throw CjcjRuntimeErrorWithLocation(
                            ErrorCode.NEG_OVERFLOW,
                            "整数取负溢出",
                            expr
                        )
            }
            case _ => ()
        }
        
        // 先求出操作数的值
        let operand = expr.right.traverse(this)

        match (expr.oper.kind) {
            // 取负
            case TokenKind.SUB => match (operand) {
                case Value.VInteger(i) =>
                    // 检查溢出：-Int64.Min 会溢出
                    if (i == Int64.Min) {
                        throw CjcjRuntimeErrorWithLocation(
                            ErrorCode.NEG_OVERFLOW,
                            "整数取负溢出",
                            expr
                        )
                    }
                    return Value.from(-i)
                case _ => throw CjcjRuntimeErrorWithLocation(
                    ErrorCode.NEG_TYPE_MISMATCH,
                    "一元负号运算的类型不是 Int64",
                    expr
                )
            }

            // 逻辑非
            case TokenKind.NOT => match (operand) {
                case Value.VBoolean(b) => return Value.from(!b)
                case _ => throw CjcjRuntimeErrorWithLocation(
                    ErrorCode.NOT_TYPE_MISMATCH,
                    "一元逻辑非运算的类型不是 Bool",
                    expr
                )
            }

            // 其他未实现操作符
            case _ => throw UnhandledTokenKind("Unary operation not supported yet: ${expr.oper.kind}")
        }
    }

    public open override func visit(par: ParenExpr): Value {
        return par.parenthesizedExpr.traverse(this)
    }

    public open override func visit(lit: LitConstExpr): Value {
        match (lit.literal.kind) {
            case TokenKind.INTEGER_LITERAL => return Value.from(Int64.parse(lit.literal.value));
            case TokenKind.STRING_LITERAL => return Value.from(lit.literal.value);
            case TokenKind.BOOL_LITERAL => return Value.from(Bool.parse(lit.literal.value));
            case TokenKind.UNIT_LITERAL => return Value.VUnit; // 不用这个的时候在while中使用break会报错？？？
            case _ => throw UnhandledTokenKind(
                lit.literal.kind.toString() + " in LitConstExpr && in line: ${getPosition(lit).line}");
        }
    }

    public open override func visit(expr: AssignExpr): Value {
        let left_name: String = match (expr.left) {
            case ref: RefExpr => ref.identifier.value
            case _ => throw UnhandledTokenKind("赋值表达式左边不太对啊")
        }
        let right = expr.right.traverse(this);
        if (let Some(curRecords) <- curRecords) {
            curRecords.setStaticRecord(left_name, right, expr);
        } else {
            throw Exception();
        }

        return Value.VUnit;
    }

    public open override func visit(ref: RefExpr): Value {
        match (ref.identifier.kind) {
            case TokenKind.IDENTIFIER =>
                if (let Some(curRecords) <- curRecords) {
                    return curRecords.getStaticValue(ref.identifier.value, ref);
                } else {
                    throw Exception();
                }
            case _ => throw UnhandledTokenKind(ref.identifier.kind.toString() + " in RefExpr");
        }
    }

    // TODO : problem：是否要先遍历一次ast把access link构建好？
    public open override func visit(block: Block): Value {
        // 加入活动记录
        var newRecords: ActivationRecords
        if (recordsStack.isEmpty()) {
            newRecords = BlockActivationRecords(None, None, None)
        } else {
            var last = recordsStack.peek()
            newRecords = BlockActivationRecords(None, last, last)
        }
        recordsStack.add(newRecords)
        curRecords = newRecords

        var ret = Value.VUnit
        for (stmt in block.nodes.iterator()) {
            ret = stmt.traverse(this)
        }
        return ret
    }

    // 这里 IfExpr 好像和手册里的不太一样，手册中的 4.5
    public open override func visit(expr: IfExpr): Value {
        var cond: Value = expr.condition.traverse(this);
        match (cond) {
            case VBoolean(b) =>
                if (b) {
                    return expr.ifBlock.traverse(this);
                } else {
                    return expr.elseBranch.traverse(this);
                }
            case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.IF_TYPE_MISMATCH, "If 条件表达式的类型不是 Bool",
                expr);
        }
    }

    public open override func visit(expr: WhileExpr): Value {
        var cond: Value = expr.condition.traverse(this);
        match (cond) {
            case VBoolean(b) =>
                var the_cond: Bool = b;
                while (the_cond) {
                    try {
                        expr.block.traverse(this);
                    } catch (e: CjcjRuntimeErrorWithLocation) {
                        match (e.code) {
                            case ErrorCode.BREAK_OUTSIDE_LOOP => break;
                            case ErrorCode.CONTINUE_OUTSIDE_LOOP => continue;
                            case _ => throw e;
                        }
                    }
                    cond = expr.condition.traverse(this)
                    match (cond) {
                        case VBoolean(nb) => the_cond = nb
                        case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.WHILE_TYPE_MISMATCH,
                            "While 条件表达式的类型不是 Bool", expr);
                    }
                }
                return Value.VUnit;
            case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.WHILE_TYPE_MISMATCH,
                "While 条件表达式的类型不是 Bool", expr);
        }
    }

    public open override func visit(call: CallExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Call Expression")
    }

    public open override func visit(_: ReturnExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Return Expression")
    }

    // 这个想法不错啊，故意抛出错误，在while块中catch
    public open override func visit(jmp: JumpExpr): Value {
        match (jmp.keyword.kind) {
            case TokenKind.BREAK => throw CjcjRuntimeErrorWithLocation(ErrorCode.BREAK_OUTSIDE_LOOP,
                "在非循环体内使用 `break`", jmp);
            case TokenKind.CONTINUE => throw CjcjRuntimeErrorWithLocation(ErrorCode.CONTINUE_OUTSIDE_LOOP,
                "在非循环体内使用 `continue`", jmp);
            case _ => throw UnhandledTokenKind("Unhandled Jump Expression Keyword: ${jmp.keyword.kind}");
        }
        throw Lab1TodoException("Jump Expression Evaluation Not Implemented")
    }

    public open override func visit(decl: VarDecl): Value {
        var exp_val: ?Value = None;

        if (let Some(exp) <- decl.initializer) {
            match (exp) {
                case b: BinaryExpr => exp_val = b.traverse(this)
                case u: UnaryExpr => exp_val = u.traverse(this)
                case l: LitConstExpr => exp_val = l.traverse(this) // 直接的字面量
                case p: ParenExpr => exp_val = p.traverse(this) // 括号表达式
                case r: RefExpr => exp_val = r.traverse(this) // 变量引用
                case _ => throw UnsupportedException("不支持的 Expr 类型")
            }
        }

        var varName: String = decl.identifier.value;
        var newRecord: Record = Record(decl.identifier, exp_val, decl.declType, decl.keyword, decl);

        if (let Some(curRecords) <- curRecords) {
            // 重复定义
            if (curRecords.findInCurRecords(varName)) {
                throw CjcjRuntimeErrorWithLocation(ErrorCode.DUPLICATED_DEF, "试图在同一静态作用域内定义同名变量", decl);
            } else {
                curRecords.addRecord(varName, newRecord);
            }
        }

        var ret = Value.VUnit;
        return ret;
    }

    public open override func visit(_: FuncParam): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Paramters")
    }

    public open override func visit(_: FuncDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Declaration")
    }

    public open override func visit(_: MainDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Main Declaration")
    }

    public open override func visit(_: ClassDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Class Declaration")
    }

    public open override func visit(_: Body): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Body")
    }

    public open override func visit(arg: Argument): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Argument")
    }

    public open override func visit(_: TypeNode): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Type Node")
    }

    public open override func visit(_: PrimitiveType): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Primitive Types")
    }

    public open override func visit(_: RefType): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Reference Type")
    }

    public open override func visit(_: VariableReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Variable Reference (ASG)")
    }

    public open override func visit(_: FuncReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Reference (ASG)")
    }

    public open override func visit(_: ClassReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Class Reference (ASG)")
    }

    public open override func visit(_: VarDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Variable Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: FuncDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Function Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: MainDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Main Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: ClassDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Class Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: MemberAccess): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Member Access")
    }

    public open override func visit(_: PrimitiveTypeExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Primitive type expression")
    }

    public open override func visit(_: RefExprWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Reference expression with reference")
    }

    public open override func visit(_: ThisSuperExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : This Super expression")
    }

    public open override func visit(_: ThisSuperReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : This Super reference")
    }

    public open override func visit(_: CallExprWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Call expression with reference")
    }

    public open override func visit(_: MemberAccessWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Member access with reference")
    }

    public open override func visit(_: InterfaceDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Declaration")
    }

    public open override func visit(_: InterfaceDeclWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Declaration with reference")
    }

    public open override func visit(_: InterfaceReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Reference")
    }
}
