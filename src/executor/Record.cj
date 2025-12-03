package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.*

class CanNotGuessType <: Exception {
    public init(message: String) {
        super("Can Not Guess Type: " + message)
    }
}

public class Record {
    var name: Token
    var value: ?Value
    var recordType: ?TokenKind // 记录变量的基础类型 (Int64, Bool, Func 等)
    var keyword: Token // var / let

    public init(_name: Token, _value: ?Value, _recordTypeNode: ?TypeNode, _keyword: Token, node: Node) {
        this.name = _name
        this.value = _value
        this.keyword = _keyword

        // 1. 确定 recordType
        if (let Some(typeNode) <- _recordTypeNode) {
            // 如果是显式类型声明
            // 注意：对于复杂的函数类型 (Int)->Int，这里可能需要根据你的 AST 实现来调整
            // 假设 FuncType 的 typeName Token 也是 FUNC
            this.recordType = typeNode.typeName.kind
        } else {
            this.recordType = None
        }

        // 2. 类型推导 (如果没有显式类型)
        if (recordType.isNone() && let Some(theValue) <- value) {
            match (theValue) {
                case VInteger(i) => recordType = TokenKind.INT64
                case VString(s) => recordType = TokenKind.IDENTIFIER
                case VBoolean(b) => recordType = TokenKind.BOOLEAN
                case VFunction(f) => recordType = TokenKind.FUNC // 推导为函数类型
                case VMain(m) => recordType = TokenKind.MAIN
                case _ => throw CanNotGuessType(theValue.toValueString());
            }
            return;
        }

        // 3. 初始值类型检查 (value 和 recordType 是否匹配)
        if (let Some(theRecordType) <- this.recordType && let Some(theValue) <- value) {
            // 函数类型检查 (Evaluator 层面通常处理了更复杂的签名，这里只做基础类型校验)
            if (theRecordType == TokenKind.FUNC && (let Value.VFunction(_) <- theValue)) {
                return;
            }
            if (theRecordType == TokenKind.MAIN && (let Value.VMain(_) <- theValue)) {
                return;
            }
            if (theRecordType == TokenKind.INT64 && (let Value.VInteger(_) <- theValue)) {
                return;
            }
            if (theRecordType == TokenKind.IDENTIFIER && (let Value.VString(_) <- theValue)) {
                return;
            }
            if (theRecordType == TokenKind.BOOLEAN && (let Value.VBoolean(_) <- theValue)) {
                return;
            }

            // 如果到了这里，说明类型不匹配
            throw CjcjRuntimeErrorWithLocation(
                ErrorCode.DEF_TYPE_MISMATCH,
                "变量定义时，赋值的类型与声明的类型不匹配",
                node
            );
        }
    }

    public func updateValue(newValue: Value, node: Node) {
        if (value.isNone()) {
            // 首次赋值（针对未初始化的 var）
            // 这里也应该检查类型，但如果是首次赋值且有 recordType，逻辑合并在下面更好
            // 现在的逻辑假设首次赋值总是合法的，或者由 Evaluator 保证类型
            value = newValue
            return;
        }

        match (keyword.kind) {
            case TokenKind.FUNC => throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_IMMUT_VAR, "试图给函数变量赋值",
                node);
            case TokenKind.LET => throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_IMMUT_VAR,
                "试图给 `let` 定义的不可变变量赋值", node);

            case TokenKind.VAR =>
                // 类型检查
                if (let Some(theRecordType) <- recordType) {
                    // === 新增：函数类型支持 ===
                    // Evaluator 已经做了签名(Signature)检查，这里只做 Kind 检查
                    if (theRecordType == TokenKind.FUNC && (let Value.VFunction(_) <- newValue)) {
                        value = newValue
                        return;
                    }
                    // ========================

                    if (theRecordType == TokenKind.INT64 && (let Value.VInteger(_) <- newValue)) {
                        value = newValue
                        return;
                    }
                    if (theRecordType == TokenKind.IDENTIFIER && (let Value.VString(_) <- newValue)) {
                        value = newValue
                        return;
                    }
                    if (theRecordType == TokenKind.BOOLEAN && (let Value.VBoolean(_) <- newValue)) {
                        value = newValue
                        return;
                    }

                    throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                        "变量赋值时，赋值的类型与声明的类型不匹配", node);
                } else {
                    // 理论上如果初始化时进行了推导，recordType 不应为 None
                    // 但如果定义时未初始化 `var a;` (如果语法支持)，则在这里推导
                    match (newValue) {
                        case VInteger(i) => recordType = TokenKind.INT64
                        case VString(s) => recordType = TokenKind.IDENTIFIER
                        case VBoolean(b) => recordType = TokenKind.BOOLEAN
                        case VFunction(f) => recordType = TokenKind.FUNC // 支持推导为函数
                        case _ => throw CanNotGuessType(newValue.toValueString());
                    }
                    value = newValue
                    return;
                }
            case _ => throw UnhandledTokenKind(keyword.kind.toString() + "  Variable keyword must be let or var");
        }
    }
}
