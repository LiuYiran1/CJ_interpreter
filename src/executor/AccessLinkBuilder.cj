package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.*

class UnhandledDeclInAccessLinkBuilder <: Exception {
    public UnhandledDeclInAccessLinkBuilder(
        let fromWhere: Node
        ) {}
    

    public override func toString(): String {
        "AccessLinkBuilder Exception at line ${getPosition(fromWhere).line}" // [10..] removes "ErrorCode."
    }
}

public class AccessLinkBuilder {



    public func buildAccessLink(program: Program) : Map<Node, ActivationRecords>{ // 返回每个block及其对应的活动记录
        var globalRecords : ActivationRecords = BlockActivationRecords("Global", None, None);
        var accessLinkMap : Map<Node, ActivationRecords> = HashMap<Node, ActivationRecords>();
        accessLinkMap.add(program, globalRecords);

        for(decl in program.decls){
            match(decl){
                case mainDecl : MainDecl => buildMainAccessLink(accessLinkMap, mainDecl);
                case funcDecl : FuncDecl => buildFuncAccessLink(accessLinkMap, funcDecl);
                case varDecl : VarDecl => () // TODO
                case _ => throw UnhandledDeclInAccessLinkBuilder(decl);
            }    
        }


        return accessLinkMap;
    }

    private func buildFuncAccessLink(accessLinkMap : Map<Node, ActivationRecords>, funcDecl : FuncDecl) : Unit{

    }

    private func buildMainAccessLink(accessLinkMap : Map<Node, ActivationRecords>, mainDecl : MainDecl) : Unit{

    }

    private func buildBlockAccessLink(accessLinkMap : Map<Node, ActivationRecords>, blockNode : BlockNode) : Unit{

    }
}