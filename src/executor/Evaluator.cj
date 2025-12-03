package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.*

public class ReturnException <: Exception {
    public let returnValue: Value

    public init(returnValue: Value) {
        this.returnValue = returnValue
    }
}

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

public open class Evaluator <: Visitor<Value> {
    var recordsMap: Map<Node, ActivationRecords> = HashMap<Node, ActivationRecords>() // 每个块对应的活动记录
    let recordsStack = ArrayStack<ActivationRecords>() // 动态栈
    var curRecords: ?ActivationRecords = None

    public init(recordsMap: Map<Node, ActivationRecords>, program: Program) {
        this.recordsMap = recordsMap
        let globalRecords = recordsMap.get(program).getOrThrow()
        recordsStack.add(globalRecords)
        curRecords = globalRecords
    }

    public open override func visit(program: Program): Value {
        // 获取全局作用域
        let globalRecords = match (curRecords) {
            case Some(r) => r
            case None => throw Exception("Evaluator initialized incorrectly")
        }

        // 注册全局函数
        for (decl in program.decls) {
            match (decl) {
                case funcDecl: FuncDecl =>
                    let funcName = funcDecl.identifier.value

                    // 检查是否与内置函数重名
                    if (funcName == "println") {
                        throw CjcjRuntimeErrorWithLocation(
                            ErrorCode.DUPLICATED_DEF,
                            "Cannot redefine builtin function 'println'",
                            funcDecl
                        )
                    }

                    let capturedEnv = globalRecords
                    let funcVal = Value.from(FuncValue(funcDecl, capturedEnv))
                    let newRecord = Record(funcDecl.identifier, Some(funcVal), None, funcDecl.keyword, funcDecl)

                    if (globalRecords.items.contains(funcName)) {
                        globalRecords.items[funcName] = newRecord
                    } else {
                        globalRecords.addRecord(funcName, newRecord, funcDecl)
                    }

                case mainDecl: MainDecl =>
                    let mainVal = Value.from(MainValue(mainDecl))
                    let record = Record(mainDecl.identifier, Some(mainVal), None, mainDecl.keyword, mainDecl)

                    if (globalRecords.items.contains("main")) {
                        globalRecords.items["main"] = record
                    } else {
                        globalRecords.addRecord("main", record, mainDecl)
                    }
                case _ => ()
            }
        }

        // 初始化全局变量
        for (decl in program.decls) {
            match (decl) {
                case varDecl: VarDecl =>
                    let varName = varDecl.identifier.value

                    // 检查是否与内置函数重名
                    if (varName == "println") {
                        throw CjcjRuntimeErrorWithLocation(
                            ErrorCode.DUPLICATED_DEF,
                            "Cannot redefine builtin function 'println' as a variable",
                            varDecl
                        )
                    }

                    // 检查初始化表达式
                    let initExpr = match (varDecl.initializer) {
                        case Some(e) => e
                        case None => throw CjcjRuntimeErrorWithLocation(
                            ErrorCode.GLOBAL_NO_INITIALIZER,
                            "全局变量必须带有初始化表达式",
                            varDecl
                        )
                    }

                    // 执行初始化
                    let initVal = initExpr.traverse(this)

                    let record = Record(
                        varDecl.identifier,
                        Some(initVal),
                        varDecl.declType,
                        varDecl.keyword,
                        varDecl
                    )

                    globalRecords.addRecord(varName, record, varDecl)

                case _ => ()
            }
        }

        // 执行 Main
        let mainValue = try {
            globalRecords.getStaticValue("main", program)
        } catch (e: CjcjRuntimeErrorWithLocation) {
            return Value.VUnit
        }

        let mainBlock = match (mainValue) {
            case Value.VMain(mv) => mv.mainDecl.block
            case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.CALLEE_NOT_FUNCTION, "main 不是 Main 类型", program)
        }

        let mainStackFrame = FuncActivationRecords("main", globalRecords, None, program, true)
        mainStackFrame.controlLink = globalRecords

        let oldRecords = curRecords
        curRecords = mainStackFrame
        recordsStack.add(mainStackFrame)

        var ret = Value.VUnit
        try {
            for (stmt in mainBlock.nodes) {
                ret = stmt.traverse(this)
            }
        } catch (re: ReturnException) {
            ret = re.returnValue
        }

        recordsStack.remove()
        curRecords = oldRecords

        return ret
    }

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
                if ((a != 0 && b != 0) && (a == -1 && b == min || b == -1 && a == min || a > max / b || a < min / b)) {
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
                        if (base != 0 && result != 0 && (result > max / base || result < min / base)) {
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
            case exp: LitConstExpr =>
                if (expr.oper.kind == TokenKind.SUB && exp.literal.value == "9223372036854775808") {
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

    // 比较两个类型节点是否相等
    private func areTypesEqual(t1: TypeNode, t2: TypeNode): Bool {
        match ((t1, t2)) {
            case (p1: PrimitiveType, p2: PrimitiveType) => return p1.typeName.value == p2.typeName.value

            case (r1: RefType, r2: RefType) => return r1.typeName.value == r2.typeName.value

            case (f1: FuncType, f2: FuncType) =>
                // 参数个数
                if (f1.paramTypes.size != f2.paramTypes.size) {
                    return false
                }
                // 2. 每个参数的类型
                for (i in 0..f1.paramTypes.size) {
                    if (!areTypesEqual(f1.paramTypes[i], f2.paramTypes[i])) {
                        return false
                    }
                }
                // 3. 返回值类型
                return areTypesEqual(f1.returnType, f2.returnType)

            case _ => return false
        }
    }

    // 检查两个函数声明的签名是否匹配 (参数列表 + 返回值)
    private func checkFuncTypeMatch(targetDecl: FuncDecl, sourceDecl: FuncDecl, node: Node): Unit {
        // 检查返回值类型
        match ((targetDecl.declType, sourceDecl.declType)) {
            case (Some(t1), Some(t2)) =>
                if (!areTypesEqual(t1, t2)) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.ASSIGN_TYPE_MISMATCH,
                        "函数返回值类型不匹配",
                        node
                    )
                }
            case (None, None) => () // 都是 Unit
            case _ => throw CjcjRuntimeErrorWithLocation(
                ErrorCode.ASSIGN_TYPE_MISMATCH,
                "函数返回值类型不匹配 (一个是 Unit，一个不是)",
                node
            )
        }

        // 检查参数个数
        if (targetDecl.params.size != sourceDecl.params.size) {
            throw CjcjRuntimeErrorWithLocation(
                ErrorCode.ASSIGN_TYPE_MISMATCH,
                "函数参数个数不匹配: 期望 ${targetDecl.params.size}, 实际 ${sourceDecl.params.size}",
                node
            )
        }

        // 检查参数类型
        for (i in 0..targetDecl.params.size) {
            let p1Type = targetDecl.params[i].paramType
            let p2Type = sourceDecl.params[i].paramType

            if (!areTypesEqual(p1Type, p2Type)) {
                throw CjcjRuntimeErrorWithLocation(
                    ErrorCode.ASSIGN_TYPE_MISMATCH,
                    "第 ${i + 1} 个参数类型不匹配",
                    node
                )
            }
        }
    }

    private func isUnitType(t: TypeNode): Bool {
        match (t) {
            case p: PrimitiveType => return p.typeName.value == "Unit"
            case _ => return false
        }
    }

    public open override func visit(expr: AssignExpr): Value {
        let left_name: String = match (expr.left) {
            case ref: RefExpr => ref.identifier.value
            case _ => throw UnhandledTokenKind("赋值表达式左边必须是标识符")
        }

        let right_val = expr.right.traverse(this)

        if (let Some(curRecords) <- curRecords) {
            // 获取记录
            let oldRecord = curRecords.getStaticRecord(left_name, expr, false)

            // 类型检查
            // 是函数的话就要参数数量类型和返回值类型相同
            match (oldRecord.value) {
                case Some(Value.VFunction(oldFuncVal)) => match (right_val) {
                    case Value.VFunction(newFuncVal) => checkFuncTypeMatch(oldFuncVal.funcDecl, newFuncVal.funcDecl,
                        expr)
                    case _ => throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.ASSIGN_TYPE_MISMATCH,
                        "不能将非函数值赋值给函数类型的变量",
                        expr
                    )
                }
                case Some(_) =>
                    // 如果原本不是函数，但新赋值是函数
                    match (right_val) {
                    case Value.VFunction(_) => throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.ASSIGN_TYPE_MISMATCH,
                        "不能将函数赋值给非函数类型的变量",
                        expr
                    )
                    //TODO：这里的设计可以优化的
                    case _ => () // 普通变量赋值封装在Record里面
                }
                case None => () // 变量未初始化
            }

            // 执行赋值
            curRecords.setStaticRecord(left_name, right_val, expr, false)
        } else {
            throw Exception("No active records")
        }

        return Value.VUnit
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
    // TODO : 小心！如果break和continue出块了要更新recordStack和curRecords
    public open override func visit(block: Block): Value {
        var newRecords: ActivationRecords
        // 保存进入 Block 之前的环境，用于最后恢复
        let previousRecords = curRecords
        let previousStackSize = recordsStack.size

        if (recordsStack.isEmpty()) {
            newRecords = BlockActivationRecords(recordsMap.get(block).getOrThrow())
        } else {
            var last = recordsStack.peek()
            let template = recordsMap.get(block).getOrThrow()
            newRecords = BlockActivationRecords(template)
            newRecords.controlLink = last
            newRecords.accessLink = last // 静态链指向当前环境
        }

        recordsStack.add(newRecords)
        curRecords = newRecords

        var ret = Value.VUnit
        for (stmt in block.nodes.iterator()) {
            ret = stmt.traverse(this)
        }

        // 强制恢复到进入 Block 之前的状态
        while (recordsStack.size > previousStackSize) {
            recordsStack.remove()
        }
        curRecords = previousRecords

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
        // 记录while外部的record
        var outterWhileRecordsNum: Int64 = recordsStack.size;

        match (cond) {
            case VBoolean(b) =>
                var the_cond: Bool = b;
                while (the_cond) {
                    try {
                        expr.block.traverse(this);
                    } catch (e: CjcjRuntimeErrorWithLocation) {
                        match (e.code) {
                            // 注意这里break和continue会导致出块，而出块需要更新recordsStack和curRecords,就是将块直接更新到while外部的块
                            case ErrorCode.BREAK_OUTSIDE_LOOP =>
                                while (outterWhileRecordsNum < recordsStack.size) {
                                    recordsStack.remove()
                                }
                                curRecords = recordsStack.peek()
                                break; // break;
                            case ErrorCode.CONTINUE_OUTSIDE_LOOP =>
                                while (outterWhileRecordsNum < recordsStack.size) {
                                    recordsStack.remove()
                                }
                                curRecords = recordsStack.peek()
                                () // continue;
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

    private func isLibFunc(call: CallExpr): Bool {
        match (call.callee) {
            case ref: RefExpr =>
                let funcName = ref.identifier.value
                match (funcName) {
                    case "println" => return true
                    case _ => return false
                }
            case _ => return false
        }
    }

    private func visitLibFunc(call: CallExpr): Value {
        match (call.callee) {
            case ref: RefExpr =>
                let funcName = ref.identifier.value
                match (funcName) {
                    case "println" =>
                        let args = call.arguments
                        if (args.size != 1) {
                            throw CjcjRuntimeErrorWithLocation(ErrorCode.CALL_ARG_COUNT_MISMATCH,
                                "内置函数 println 需要 1 个参数，实际 ${args.size} 个", call)
                        }
                        let argValue = args[0].traverse(this)
                        match (argValue) {
                            case Value.VInteger(i) => println(i.toString())
                            case Value.VString(s) => println(s)
                            case Value.VBoolean(b) => println(b.toString())
                            case Value.VUnit => println("()")
                            case Value.VFunction(f) => println("<Function>")
                            case Value.VMain(f) => println("<Function main>")
                        }
                        return Value.VUnit
                    case _ => throw UnhandledTokenKind("Unhandled Lib Function: ${funcName}")
                }
            case _ => throw UnhandledTokenKind("Callee of Lib Function is not RefExpr")
        }
    }

    // 检查 Value 的类型是否与声明的 TypeNode 匹配
    private func checkValueTypeMatch(val: Value, typeNode: TypeNode): Bool {
        match (typeNode) {
            case pt: PrimitiveType => match (pt.typeName.value) {
                case "Int64" => match (val) {
                    case VInteger(_) => true;
                    case _ => false
                }
                case "Bool" => match (val) {
                    case VBoolean(_) => true;
                    case _ => false
                }
                case "Unit" => match (val) {
                    case VUnit => true;
                    case _ => false
                }
                case "String" => match (val) {
                    case VString(_) => true;
                    case _ => false
                }
                case _ => false
            }

            case ft: FuncType => match (val) {
                case Value.VFunction(funcVal) =>
                    let decl = funcVal.funcDecl

                    // 参数个数
                    if (decl.params.size != ft.paramTypes.size) {
                        return false
                    }

                    // 参数类型
                    for (i in 0..decl.params.size) {
                        // decl.params[i].paramType 是 AST 中定义的参数类型
                        // ft.paramTypes[i] 是目标函数类型的参数类型
                        if (!areTypesEqual(decl.params[i].paramType, ft.paramTypes[i])) {
                            return false
                        }
                    }

                    // 返回值类型
                    match (decl.declType) {
                        case Some(declRetType) =>
                            // 函数声明有返回值，比较它和目标类型返回值
                            return areTypesEqual(declRetType, ft.returnType)
                        case None => return isUnitType(ft.returnType)
                    }

                case _ => false // 如果期望函数类型，但给的不是函数值
            }

            case rt: RefType =>
                // TODO：这里目前将RefType视作true
                true

            case _ => false
        }
    }

    public open override func visit(call: CallExpr): Value {
        if (isLibFunc(call)) {
            return visitLibFunc(call)
        }

        let calleeValue = call.callee.traverse(this)

        let calleeBlock: Block
        let funcDecl: FuncDecl
        var closureEnv: ?ActivationRecords = None
        var isMainCall = false

        match (calleeValue) {
            case Value.VFunction(fv) =>
                if (let Some(theBlock) <- fv.funcDecl.block) {
                    calleeBlock = theBlock
                    funcDecl = fv.funcDecl
                    closureEnv = fv.capturedEnv
                } else {
                    throw CjcjRuntimeErrorWithLocation(ErrorCode.FUNC_MISSING_BODY, "函数无体", fv.funcDecl)
                }
            case Value.VMain(mv) =>
                calleeBlock = mv.mainDecl.block
                // 构造一个假的 FuncDecl 用于统一处理，或者特殊处理 Main
                // Main 通常没有参数和返回值，这里简单处理
                // 注意：如果 Main 有特殊逻辑，需分开写
                // 这里为了复用逻辑，假设 Main 是特殊的 FuncDecl
                isMainCall = true

                // Main 特例处理
                let mainStackFrame = FuncActivationRecords(
                    "main",
                    match (curRecords) {
                        case Some(r) => r;
                        case None => throw Exception("No Global")
                    },
                    None,
                    mv.mainDecl,
                    true
                )
                mainStackFrame.controlLink = curRecords
                let oldRecords = curRecords
                curRecords = mainStackFrame
                recordsStack.add(mainStackFrame)
                var ret = Value.VUnit
                try {
                    for (stmt in calleeBlock.nodes) {
                        ret = stmt.traverse(this)
                    }
                } catch (re: ReturnException) {
                    ret = re.returnValue
                }
                recordsStack.remove()
                curRecords = oldRecords
                return ret

            case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.CALLEE_NOT_FUNCTION, "试图调用非函数", call)
        }

        // 检查参数个数
        if (funcDecl.params.size != call.arguments.size) {
            throw CjcjRuntimeErrorWithLocation(
                ErrorCode.CALL_ARG_COUNT_MISMATCH,
                "函数参数个数不匹配: 期望 ${funcDecl.params.size}, 实际 ${call.arguments.size}",
                call
            )
        }

        // 依次计算实参并检查类型 (即时检查)
        let actualArgumentsValue = ArrayList<Value>()
        for (i in 0..call.arguments.size) {
            let argExpr = call.arguments[i]
            let paramDecl = funcDecl.params[i]

            // 计算实参值
            let argValue = argExpr.traverse(this)

            // 注意：在 argExpr 处报错
            if (!checkValueTypeMatch(argValue, paramDecl.paramType)) {
                throw CjcjRuntimeErrorWithLocation(
                    ErrorCode.CALL_ARG_TYPE_MISMATCH,
                    "第 ${i + 1} 个参数类型不匹配",
                    argExpr // 报错位置在实参表达式
                )
            }

            actualArgumentsValue.add(argValue)
        }

        let previousRecords = curRecords
        let previousStackSize = recordsStack.size

        let funcRecords: FuncActivationRecords
        if (let Some(templateRecords) <- recordsMap.get(calleeBlock)) {
            funcRecords = match (templateRecords) {
                case fr: FuncActivationRecords => FuncActivationRecords(fr)
                case _ => throw Exception("Records map type mismatch")
            }

            // 设置静态父级 (闭包环境)
            if (closureEnv.isSome()) {
                funcRecords.accessLink = closureEnv
            } else {
                // 如果没有闭包环境（例如全局函数），使用模板的或者 fallback
                funcRecords.accessLink = templateRecords.accessLink
            }

            funcRecords.controlLink = curRecords

            curRecords = funcRecords
            recordsStack.add(funcRecords)
        } else {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR, "Undefined func execution context", call)
        }

        // 绑定参数 (定义不可变变量)
        funcRecords.assignParams(actualArgumentsValue, call)

        // 执行函数体
        var returnValue: Value = Value.VUnit
        try {
            // 手动遍历 Block!怕又多压一次栈
            for (stmt in calleeBlock.nodes) {
                returnValue = stmt.traverse(this)
            }
        } catch (re: ReturnException) {
            returnValue = re.returnValue
        }

        // 检查返回值类型匹配
        // 若返回值类型与函数声明的返回类型不匹配，则在函数定义 FuncDecl 处报错
        if (let Some(returnTypeNode) <- funcDecl.declType) {
            // 检查 returnValue 是否匹配 returnTypeNode
            if (!checkValueTypeMatch(returnValue, returnTypeNode)) {
                throw CjcjRuntimeErrorWithLocation(
                    ErrorCode.FUNC_RETURN_TYPE_MISMATCH,
                    "函数返回值类型不匹配",
                    funcDecl // 报错位置在函数定义处
                )
            }
        }

        // 恢复栈
        while (recordsStack.size > previousStackSize) {
            recordsStack.remove()
        }
        curRecords = previousRecords

        return returnValue
    }

    public open override func visit(returnExpr: ReturnExpr): Value {
        throw ReturnException(match (returnExpr.expr) {
            case Some(e) => e.traverse(this)
            case None => Value.VUnit
        })
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
            exp_val = exp.traverse(this)
        }

        var varName: String = decl.identifier.value;
        var newRecord: Record = Record(decl.identifier, exp_val, decl.declType, decl.keyword, decl);

        if (let Some(current) <- curRecords) {

            // 【新增逻辑】检查当前块内是否重复定义，md成石山代码了
            var ptr = current
            while (true) {
                // 检查当前层是否有同名变量
                if (ptr.items.contains(varName)) {
                    throw CjcjRuntimeErrorWithLocation(
                        ErrorCode.DUPLICATED_DEF,
                        "变量重复定义：${varName}",
                        decl
                    )
                }

                // 如果当前节点是 VarDecl 产生的链式节点，还需要继续往上查前一个变量定义。
                if (ptr.isVarChainScope) {
                    if (let Some(parent) <- ptr.accessLink) {
                        ptr = parent
                    } else {
                        break // 理论上不应发生，链式节点肯定有 parent
                    }
                } else {
                    // 如果当前节点不是链式节点
                    break
                }
            }

            let chainedScope = BlockActivationRecords(
                "scope_" + varName,
                current.controlLink,
                current // Access Link 指向旧的 current
            )

            // 标记这是一个变量链式作用域
            chainedScope.isVarChainScope = true

            chainedScope.addRecord(varName, newRecord, decl)

            recordsStack.remove()
            recordsStack.add(chainedScope)

            curRecords = chainedScope
        }

        return Value.VUnit;
    }

    public open override func visit(_: FuncParam): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Paramters")
    }

    public open override func visit(funcDecl: FuncDecl): Value {
        let capturedEnv = curRecords // 捕获当前环境
        let funcVal = Value.from(FuncValue(funcDecl, capturedEnv))
        let funcName = funcDecl.identifier.value
        let newRecord = Record(funcDecl.identifier, Some(funcVal), None, funcDecl.keyword, funcDecl)

        // 函数声明通常不需要开启新Scope，直接加到当前Scope即可
        // 这样递归调用时能找到自己
        if (let Some(current) <- curRecords) {
            current.addRecord(funcName, newRecord, funcDecl)
        }
        return Value.VUnit
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
        return arg.expr.traverse(this)
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
