package cjcj.executor

import std.collection.*
import cjcj.visitor.*
import cjcj.scanner.*

public class FuncActivationRecords <: ActivationRecords {
    public var return_addr: ?Node // TODO: 还没想好这里使用什么类型，可以存Ast的节点？
    public var save_returnv_addr: ?Int64 // 保存返回值接收的地址，是活动记录中的 items 的索引，还是说存引用比较好？

    //public let paramNames: List<String>
    public var returnType: ?TypeNode
    public var isMain = false
    public let params: ArrayList<FuncParam>

    public init(_name: ?String, _accessLink: ?ActivationRecords, _returnType: ?TypeNode, node: Node, _isMain: Bool) {
        super(_name, _accessLink)
        this.params = ArrayList<FuncParam>()
        this.return_addr = None
        this.save_returnv_addr = None
        this.returnType = _returnType

        this.isMain = _isMain
        // 静态检查函数参数和返回值类型
        if (!isMain) {
            this.checkArguReturnTypeDecl(node)
        }
    }

    public init(funcAR: FuncActivationRecords) {
        super(funcAR)
        this.params = ArrayList<FuncParam>()
        for (name in funcAR.params) {
            this.params.add(name)
        }
        this.return_addr = funcAR.return_addr
        this.save_returnv_addr = funcAR.save_returnv_addr
        this.returnType = funcAR.returnType
        this.isMain = funcAR.isMain
    }

    private func checkArguReturnTypeDecl(node: Node): Unit {
        // 返回类型
        if (this.returnType.isNone()) {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.FUNC_MISSING_RETURN_TYPE, "函数缺少返回值类型声明", node)
        }
    }

    public func addParamRecord(param: FuncParam, record: Record, node: Node): Unit {
        super.addRecord(param.name.value, record, node)
        this.params.add(param)
    }

    public func assignParams(actualArgumentsValue: ArrayList<Value>, callNode: Node): Unit {
        // 这里的 params 应该是你在构建 recordsMap 时存进去的参数列表
        // 如果你现在的 params 只是 List<String>，建议改成 List<FuncParam>

        if (this.params.size != actualArgumentsValue.size) {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.CALL_ARG_COUNT_MISMATCH, "参数数量不匹配", callNode)
        }

        for (i in 0..params.size) {
            let paramDef = params[i] // 假设这是 FuncParam 类型
            let paramName = paramDef.name.value // 获取参数名（真的）
            let actualValue = actualArgumentsValue[i]

            // 核心修复：这里不再是 items[name].updateValue
            // 而是创建一个新的 Record 并 add 进去

            // 注意：Record 的构造函数需要 (Token, Value, TypeNode, TokenKind, Node)
            // 你需要根据你的 Record 定义来构造。
            // 这里假设 paramDef.identifier 是 Token

            let newRecord = Record(
                paramDef.name, // 标识符 Token
                Some(actualValue), // 初始值
                paramDef.paramType, // 类型节点
                paramDef.keyword, // 关键字 TokenKind
                paramDef // 关联的 AST 节点
            )

            // 将新创建的参数记录添加到当前的活动记录中
            this.addRecord(paramName, newRecord, callNode)
        }
    }
}
