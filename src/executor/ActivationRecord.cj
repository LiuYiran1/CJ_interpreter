package cjcj.executor

import std.collection.*

public abstract open class ActivationRecord {
    var name : ?String;
    var controlLink : ?ActivationRecord; 
    var accessLink : ?ActivationRecord; // 用来实现闭包
    let items : List<Record>;

    public init(_name : ?String, _controlLink : ?ActivationRecord, _accessLink : ?ActivationRecord){
        this.name = _name;
        this.controlLink = _controlLink;
        this.accessLink = _accessLink;
        this.items = ArrayList<Record>();
    }
    
}
