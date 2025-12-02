package cjcj.executor

import std.collection.*
import cjcj.visitor.*

public abstract class ActivationRecords {
    public var name: ?String
    public var controlLink: ?ActivationRecords // 调用链
    public var accessLink: ?ActivationRecords // 静态链（闭包/静态作用域）
    public let items: HashMap<String, Record>

    public init(_name: ?String, _accessLink: ?ActivationRecords) {
        this.name = _name
        this.controlLink = None
        this.accessLink = _accessLink
        this.items = HashMap<String, Record>()
    }

    public init(_name: ?String, _controlLink: ?ActivationRecords, _accessLink: ?ActivationRecords) {
        this.name = _name
        this.controlLink = _controlLink
        this.accessLink = _accessLink
        this.items = HashMap<String, Record>()
    }

    /** ---------------- 静态作用域查找 ---------------- */
    public func getStaticRecord(name: String, node: Node): Record {
        if (items.contains(name)) {
            return items[name]
        } else if (let Some(last) <- accessLink) {
            return last.getStaticRecord(name, node)
        } else {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR, "静态作用域下未定义变量", node)
        }
    }


    public func getStaticValue(name: String, node: Node): Value {
        var record: Record = this.getStaticRecord(name, node)
        if (let Some(val) <- record.value) {
            return val
        } else {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNINITIALIZED_VAR, "静态作用域下未初始化变量", node)
        }
    }

    public func setStaticRecord(name: String, value: Value, node: Node): Unit {
        if (items.contains(name)) {
            items[name].updateValue(value, node)
        } else if (let Some(last) <- accessLink) {
            last.setStaticRecord(name, value, node)
        } else {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR, "静态作用域下未定义变量", node)
        }
    }

    /** ---------------- 辅助方法 ---------------- */
    public func findInCurRecords(name: String): Bool {
        return items.contains(name)
    }

    public open func addRecord(name: String, record: Record, node: Node): Unit {
        if (this.findInCurRecords(name)) {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.DUPLICATED_DEF, "重复定义变量或函数：${name}", node)
        } else {
            items.add(name, record)
        }
    }

    public func getName(): String {
        if (let Some(name) <- this.name) {
            return name
        }
        return "None"
    }
}
