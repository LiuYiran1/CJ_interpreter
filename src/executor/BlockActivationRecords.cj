package cjcj.executor

import std.collection.*

public class BlockActivationRecords <: ActivationRecords {
    public init(_name: ?String, _controlLink: ?ActivationRecords, _accessLink: ?ActivationRecords) {
        super(_name, _controlLink, _accessLink)
    }
}
