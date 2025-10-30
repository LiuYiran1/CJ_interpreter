package cjcj.executor

import cjcj.visitor.*
import std.deriving.Derive

@Derive[ToString]
public enum ErrorCode {
    | ADD_TYPE_MISMATCH // 加法两侧类型不受支持。
    | ADD_OVERFLOW // 整数加法结果超出 `Int64` 表示范围。
    | SUB_TYPE_MISMATCH // 减法两侧类型不受支持。
    | SUB_OVERFLOW // 整数减法结果超出 `Int64` 表示范围。
    | MUL_TYPE_MISMATCH // 乘法两侧类型不受支持。
    | MUL_OVERFLOW // 整数乘法结果超出 `Int64` 表示范围。
    | DIV_TYPE_MISMATCH // 除法两侧类型不受支持。
    | DIV_BY_ZERO // 整数除法的除数为 0。
    | MOD_TYPE_MISMATCH // 取余两侧类型不受支持。
    | MOD_BY_ZERO // 取余运算的除数为 0。
    | EXP_NEGATIVE_POWER // 指数为负数的幂运算不被支持。
    | EXP_OVERFLOW // 幂运算结果超出 `Int64` 表示范围。
    | EXP_TYPE_MISMATCH // 幂运算两侧类型不受支持。
    | CMP_TYPE_MISMATCH // 比较运算两侧的类型不受支持。
    | EQ_TYPE_MISMATCH // 比较两个不一样的类型。
    | NEQ_TYPE_MISMATCH // 比较两个不一样的类型。
    | AND_TYPE_MISMATCH // 在计算中遇到逻辑与的任一操作数不是 `Bool`。
    | OR_TYPE_MISMATCH // 在计算中遇到逻辑或的任一操作数不是 `Bool`。
    | NOT_TYPE_MISMATCH // 逻辑非的操作数不是 `Bool`。
    | NEG_TYPE_MISMATCH // 一元取负的操作数不是 `Int64`。
    | NEG_OVERFLOW // 一元取负运算发生溢出。
    | IF_TYPE_MISMATCH // if 条件表达式的结果不是 `Bool`。
    | WHILE_TYPE_MISMATCH // while 条件表达式的结果不是 `Bool`。
    | BREAK_OUTSIDE_LOOP // 在非循环体内使用 `break`。
    | CONTINUE_OUTSIDE_LOOP // 在非循环体内使用 `continue`.
    | ASSGIN_IMMUT_VAR // 试图给 `let` 定义的不可变变量赋值。
    | ASSIGN_TYPE_MISMATCH // 试图给变量赋值成不同的类型。
    | UNDEFINED_VAR // 试图使用未定义的变量。
    | DUPLICATED_DEF // 试图在同一静态作用域内定义同名变量。
    | DEF_TYPE_MISMATCH // 变量定义时，赋值的类型与声明的类型不匹配。
    | UNINITIALIZED_VAR // 试图读取未初始化的变量的值。
}

public class CjcjRuntimeErrorWithLocation <: Exception {
    CjcjRuntimeErrorWithLocation(
        public let code: ErrorCode,
        public let extraMessage: String,
        public let fromWhere: Node
    ) {}

    public override func toString(): String {
        "Error at line ${getPosition(fromWhere).line}: [${code.toString()[10..]}]: ${extraMessage}" // [10..] removes "ErrorCode."
    }
}
