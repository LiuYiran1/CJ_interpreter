package cjcj.executor

import std.collection.*
import cjcj.visitor.*
import cjcj.scanner.*

class CanNotGuessType <: Exception{
    public init(message: String) {
        super("Can Not Guess Type: " + message)
    }
}

public class Record {
    var name : Token
    var value : ?Value
    var recordType : ?TokenKind
    var keyword : Token
    
    public init(_name : Token, _value : ?Value, _recordTypeNode : ?TypeNode, _keyword : Token, node : Node){
        this.name = _name;
        this.value = _value;
        if(let Some(_recordTypeNode) <- _recordTypeNode){
            this.recordType = _recordTypeNode.typeName.kind;
            println(recordType.toString());
        } else {
            this.recordType = None;
        }
        this.keyword = _keyword;

        // 类型推导
        if(recordType.isNone() && let Some(theValue) <- value){
            match(theValue){
                case VInteger(i) => recordType = TokenKind.INT64;
                case VString(s) => recordType = TokenKind.IDENTIFIER; // String会被识别成标识符
                case VBoolean(b) => recordType = TokenKind.BOOLEAN;
                case _ => throw CanNotGuessType(theValue.toValueString());
            }
            return;
        }
        // value和record_type对不上
        if(let Some(theRecordType) <- this.recordType && let Some(theValue) <- value){
            if(theRecordType == TokenKind.INT64 && (let Value.VInteger(i) <- theValue)){
                return;
            }
            if(theRecordType == TokenKind.IDENTIFIER && (let Value.VString(i) <- theValue)){
                return;
            }
            if(theRecordType == TokenKind.BOOLEAN && (let Value.VString(i) <- theValue)){
                return;
            }
            throw CjcjRuntimeErrorWithLocation(ErrorCode.DEF_TYPE_MISMATCH, "变量定义时，赋值的类型与声明的类型不匹配", node);
        }

    }

    public func updateValue(value: Value){
        
    }
}
