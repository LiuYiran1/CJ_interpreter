package cjcj.env

import std.collection.*

public class BlockActivationRecord <: ActivationRecord {

    public init(_controlLink : ActivationRecord, _accessLink : ActivationRecord){
        super(_controlLink, _accessLink)
    }
    
}

