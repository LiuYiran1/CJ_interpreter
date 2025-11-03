package cjcj.executor
import std.collection.*

public class BlockActivationRecord <: ActivationRecord {

    public init(_name : ?String, _controlLink : ?ActivationRecord, _accessLink : ?ActivationRecord){
        super(_name, _controlLink, _accessLink)
    }
    
}

