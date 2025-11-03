package cjcj.env

import std.collection.*

public class FuncActivationRecord <: ActivationRecord {
    var return_addr : String; // TODO: 还没想好这里使用什么类型，可以存Ast的节点？
    var save_returnv_addr : Int64; // 保存返回值接收的地址，是活动记录中的 items 的索引，还是说存引用比较好？
    var arguments : List<Record>;

    public init(_controlLink : ActivationRecord, _accessLink : ActivationRecord
                , _return_addr:String, _save_returnv_addr : Int64, _arguments : List<Record>){
        super(_controlLink, _accessLink)
        this.return_addr = _return_addr;
        this.save_returnv_addr = _save_returnv_addr;
        this.arguments = _arguments;
    }
    
}
