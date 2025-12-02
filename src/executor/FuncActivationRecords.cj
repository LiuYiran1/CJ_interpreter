package cjcj.executor

import std.collection.*
import cjcj.visitor.*

public class FuncActivationRecords <: ActivationRecords {
    public var return_addr: ?Node // TODO: 还没想好这里使用什么类型，可以存Ast的节点？
    public var save_returnv_addr: ?Int64 // 保存返回值接收的地址，是活动记录中的 items 的索引，还是说存引用比较好？
    public let paramNames: List<String>
    public var returnType: ?TypeNode
    public var isMain = false

    public init(_name: ?String, _accessLink: ?ActivationRecords, _returnType: ?TypeNode, node : Node, _isMain: Bool) {
        super(_name, _accessLink)
        this.paramNames = ArrayList<String>()
        this.return_addr = None
        this.save_returnv_addr = None
        this.returnType = _returnType
        if(let Some(rt) <- returnType){
            match (rt){
                case funcTypeNode: FuncType => println("是函数")
                case pri: PrimitiveType => println("是基础类型")
                case _ => println("是啥")
            }
        }
        this.isMain = _isMain
        // 静态检查函数参数和返回值类型
        if(!isMain){
            this.checkArguReturnTypeDecl(node)
        }
    }

    private func checkArguReturnTypeDecl(node: Node): Unit {
        // 返回类型
        if(this.returnType.isNone()) {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.FUNC_MISSING_RETURN_TYPE,
                "函数缺少返回值类型声明", node)
        }
    }

    public func addParamRecord(name: String, record: Record, node: Node): Unit {
        super.addRecord(name, record, node)
        this.paramNames.add(name)
    }

    public func assignParams(actualArgumentsValue: ArrayList<Value>, node: Node): Unit {
        if (paramNames.size != actualArgumentsValue.size) {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.CALL_ARG_COUNT_MISMATCH,
                "函数参数个数不匹配，期望 ${paramNames.size} 个，实际 ${actualArgumentsValue.size} 个", node)
        }
        if(paramNames.size == 0) {
            return;
        }
        for (i in 0..paramNames.size) {
            let paramName = paramNames[i]
            let actualValue = actualArgumentsValue[i]
            this.items[paramName].updateValue(actualValue, node)
        }
    }
}
