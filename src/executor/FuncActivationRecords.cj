package cjcj.executor

import std.collection.*
import cjcj.visitor.*

public class FuncActivationRecords <: ActivationRecords {
    public var return_addr: ?Node // TODO: 还没想好这里使用什么类型，可以存Ast的节点？
    public var save_returnv_addr: ?Int64 // 保存返回值接收的地址，是活动记录中的 items 的索引，还是说存引用比较好？
    public let paramNames: List<String>

    public init(_name: ?String, _accessLink: ?ActivationRecords) {
        super(_name, _accessLink)
        this.paramNames = ArrayList<String>()
        this.return_addr = None
        this.save_returnv_addr = None
    }

    public init(_name: ?String, _controlLink: ?ActivationRecords, _accessLink: ?ActivationRecords, _return_addr: Node,
        _save_returnv_addr: Int64, _paramNames: List<String>) {
        super(_name, _controlLink, _accessLink)
        this.return_addr = _return_addr
        this.save_returnv_addr = _save_returnv_addr
        this.paramNames = _paramNames
    }

    public override func addRecord(name: String, record: Record, node: Node): Unit {
        super.addRecord(name, record, node)
        this.paramNames.add(name)
    }

    public func assignParams(actualArgumentsValue: ArrayList<Value>, node: Node): Unit {
        if (paramNames.size != actualArgumentsValue.size) {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.CALL_ARG_COUNT_MISMATCH,
                "函数参数个数不匹配，期望 ${paramNames.size} 个，实际 ${actualArgumentsValue.size} 个", node)
        }
        for (i in 0..paramNames.size) {
            let paramName = paramNames[i]
            let actualValue = actualArgumentsValue[i]
            this.items[paramName].updateValue(actualValue, node)
        }
    }
}
