package cjcj.executor

import std.collection.*
import cjcj.visitor.*

public class Record {
    var name : String;
    var value : Value;
    var value_type : TypeNode
    
    public init(_name : String, _value : Value, _value_type : TypeNode){
        this.name = _name;
        this.value = _value;
        this.value_type = _value_type;
    }
}
