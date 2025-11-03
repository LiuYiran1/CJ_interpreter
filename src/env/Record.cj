package cjcj.env

import std.collection.*
import cjcj.executor.*;

public class Record {
    var name : String;
    var value : Value;
    
    public init(_name : String, _value : Value){
        this.name = _name;
        this.value = _value;
    }
}
