package cjcj.executor

import std.collection.*
import cjcj.visitor.*

public abstract open class ActivationRecords {
    public var name : ?String;
    public var controlLink : ?ActivationRecords; 
    public var accessLink : ?ActivationRecords; // 用来实现闭包
    public let items: HashMap<String, Record>;

    public init(_name : ?String, _controlLink : ?ActivationRecords, _accessLink : ?ActivationRecords){
        this.name = _name;
        this.controlLink = _controlLink;
        this.accessLink = _accessLink;
        this.items = HashMap<String, Record>();
    }

    public func getRecordValue(name: String, node: Node): Value{
        var record : Record = this.getRecord(name, node);
        if(let Some(val) <- record.value){
           return val;
        } else {
            // 没赋值就用
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNINITIALIZED_VAR, "试图读取未初始化的变量的值", node);
        }
    }

    public func getRecord(name: String, node: Node): Record {
        if(items.contains(name)){
            return items[name];
        }else{
            if(let Some(last) <- controlLink){
                return last.getRecord(name, node);
            } else {
                throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR, "试图使用未定义的变量", node);
            }
        }
    }

    public func setRecord(name: String, value: Value, node: Node): Unit {
        if(items.contains(name)){
            items[name].updateValue(value);
        }else{
            if(let Some(last) <- controlLink){
                last.setRecord(name, value, node);
            } else {
                throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR, "试图使用未定义的变量", node);
            }
        }
    }

    public func findInCurRecords(name : String): Bool{
        return items.contains(name);
    }

    public func addRecord(name: String, record: Record){
        items.add(name, record);
    }

    
}
