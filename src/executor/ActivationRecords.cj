package cjcj.executor

import std.collection.*
import cjcj.visitor.*
import cjcj.scanner.*

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

    public init(activationRecords: ActivationRecords) {
        this.name = activationRecords.name
        this.controlLink = activationRecords.controlLink
        this.accessLink = activationRecords.accessLink
        this.items = HashMap<String, Record>()
    }

    public init(_name: ?String, _controlLink: ?ActivationRecords, _accessLink: ?ActivationRecords) {
        this.name = _name
        this.controlLink = _controlLink
        this.accessLink = _accessLink
        this.items = HashMap<String, Record>()
    }

    public func getStaticRecord(name: String, node: Node, isNonLocal: Bool): Record {
        if (items.contains(name)) {
            let record = items[name]

            // 【关键修复】判断当前是否为全局作用域
            // 如果 accessLink 为 None，说明已经到了最顶层（Global），
            // 全局变量不受“内层函数不可访问外层可变变量”的规则限制。
            let isGlobal = this.accessLink.isNone()

            // 只有在非全局作用域、且跨越了函数边界、且变量可变时，才报错
            if (!isGlobal && isNonLocal && record.keyword.kind == TokenKind.VAR) {
                throw CjcjRuntimeErrorWithLocation(
                    ErrorCode.FUNC_USE_MUTABLE_NONLOCAL,
                    "内层函数不允许访问外层函数的可变非局部变量：${name}",
                    node
                )
            }
            return record
        } else if (let Some(last) <- accessLink) {
            // 判断下一次查找是否视为“非局部”
            var nextIsNonLocal = isNonLocal
            match (this) {
                case _: FuncActivationRecords => nextIsNonLocal = true
                case _ => ()
            }
            return last.getStaticRecord(name, node, nextIsNonLocal)
        } else {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR, "静态作用域下未定义变量：" + name, node)
        }
    }

    public func getStaticValue(name: String, node: Node): Value {
        // 初始调用 isNonLocal = false
        var record: Record = this.getStaticRecord(name, node, false)
        if (let Some(val) <- record.value) {
            return val
        } else {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNINITIALIZED_VAR, "静态作用域下未初始化变量：" + name, node)
        }
    }

    public func setStaticRecord(name: String, value: Value, node: Node, isNonLocal: Bool): Unit {
        if (items.contains(name)) {
            let record = items[name]

            // 【关键修复】同上，全局变量允许被修改
            let isGlobal = this.accessLink.isNone()

            if (!isGlobal && isNonLocal && record.keyword.kind == TokenKind.VAR) {
                throw CjcjRuntimeErrorWithLocation(
                    ErrorCode.FUNC_USE_MUTABLE_NONLOCAL,
                    "内层函数不允许访问外层函数的可变非局部变量：${name}",
                    node
                )
            }
            items[name].updateValue(value, node)
        } else if (let Some(last) <- accessLink) {
            var nextIsNonLocal = isNonLocal
            match (this) {
                case _: FuncActivationRecords => nextIsNonLocal = true
                case _ => ()
            }
            last.setStaticRecord(name, value, node, nextIsNonLocal)
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
