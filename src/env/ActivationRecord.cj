package cjcj.env

import std.collection.*

public abstract open class ActivationRecord {
    var controlLink : ActivationRecord; 
    var accessLink : ActivationRecord; // 用来实现闭包
    let items : List<Record>;

    public init(_controlLink : ActivationRecord, _accessLink : ActivationRecord){
        this.controlLink = _controlLink;
        this.accessLink = _accessLink;
        this.items = ArrayList<Record>();
    }
    
}
