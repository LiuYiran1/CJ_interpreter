package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.*

class UnhandledDeclInAccessLinkBuilder <: Exception {
    public UnhandledDeclInAccessLinkBuilder(let fromWhere: Node) {}

    public override func toString(): String {
        "AccessLinkBuilder Exception at line ${getPosition(fromWhere).line}" // [10..] removes "ErrorCode."
    }
}

public class AccessLinkBuilder {
    var accessLinkMap: Map<Node, ActivationRecords> = HashMap<Node, ActivationRecords>();
    var tabNum = 0

    public func buildAccessLink(program: Program): Map<Node, ActivationRecords> { // 返回每个block及其对应的活动记录
        var globalRecords: ActivationRecords = BlockActivationRecords("Global", None);
        accessLinkMap.add(program, globalRecords);
        printNode("program")

        for (decl in program.decls) {
            match (decl) {
                case mainDecl: MainDecl => buildMainAccessLink(mainDecl, globalRecords);
                case funcDecl: FuncDecl => buildFuncAccessLink(funcDecl, globalRecords);
                case varDecl: VarDecl => ()
                case funcParam: FuncParam => ()
                case _ => throw UnhandledDeclInAccessLinkBuilder(decl);
            }
        }

        return accessLinkMap;
    }

    private func buildFuncAccessLink(funcDecl: FuncDecl, outterRecords: ActivationRecords): Unit {
        tabNum++;
        printNode(funcDecl.identifier.value)

        if (let Some(theBlock) <- funcDecl.block) {
            // 和外层连接
            var funcRecords: FuncActivationRecords = FuncActivationRecords(funcDecl.identifier.value,
                Some(outterRecords));
            accessLinkMap.add(theBlock, funcRecords);

            // 处理函数内部的声明
            buildBlockAccessLink(theBlock, outterRecords);
        }

        tabNum--;
    }

    private func buildMainAccessLink(mainDecl: MainDecl, outterRecords: ActivationRecords): Unit {
        tabNum++;
        printNode("main")

        var theBlock = mainDecl.block

        // 和外层连接
        var funcRecords: FuncActivationRecords = FuncActivationRecords(mainDecl.identifier.value, Some(outterRecords));
        accessLinkMap.add(theBlock, funcRecords);

        // 处理函数内部的声明
        buildBlockAccessLink(theBlock, outterRecords);

        tabNum--;
    }

    private func buildBlockAccessLink(blockNode: Block, outterRecords: ActivationRecords): Unit {

        tabNum++;
        printNode("block")

        var blockRecords: ActivationRecords = outterRecords;
        if(!this.accessLinkMap.contains(blockNode)) {
            blockRecords = BlockActivationRecords(None, Some(outterRecords));
            accessLinkMap.add(blockNode, blockRecords);
        }
        // 处理块内部的声明
        for (node in blockNode.nodes) {
            match (node) {
                case funcDecl: FuncDecl => buildFuncAccessLink(funcDecl, blockRecords);
                case ifExp : IfExpr => () // TODO:
                case whileExpr : WhileExpr => () // TODO:
                case _ => ()
            }
        }

        tabNum--;
    }

    private func printNode(name: String) {
        println("  " * tabNum + name)
    }
}
