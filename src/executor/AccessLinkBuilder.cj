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
        if (let Some(theBlock) <- funcDecl.block) {
            // 和外层连接
            var funcRecords: FuncActivationRecords = FuncActivationRecords(funcDecl.identifier.value,
                Some(outterRecords));
            accessLinkMap.add(theBlock, funcRecords);

            // 处理函数内部的声明
            buildBlockAccessLink(theBlock, funcRecords);
        }
    }

    private func buildMainAccessLink(mainDecl: MainDecl, outterRecords: ActivationRecords): Unit {
        var theBlock = mainDecl.block

        // 和外层连接
        var funcRecords: FuncActivationRecords = FuncActivationRecords("main", Some(outterRecords));
        accessLinkMap.add(theBlock, funcRecords);

        // 处理函数内部的声明
        buildBlockAccessLink(theBlock, funcRecords);
    }

    private func buildBlockAccessLink(blockNode: Block, outterRecords: ActivationRecords): Unit {
        var blockRecords: ActivationRecords = outterRecords;
        if (!this.accessLinkMap.contains(blockNode)) {
            blockRecords = BlockActivationRecords(None, Some(outterRecords))
            accessLinkMap.add(blockNode, blockRecords);
        }
        // 处理块内部的声明
        for (node in blockNode.nodes) {
            match (node) {
                case funcDecl: FuncDecl => buildFuncAccessLink(funcDecl, blockRecords);
                case ifExp: IfExpr =>
                    buildBlockAccessLink(ifExp.ifBlock, blockRecords)
                    match (ifExp.elseBranch) {
                        case elseBlock: Block => buildBlockAccessLink(elseBlock, blockRecords)
                        case _ => throw Exception("else不是block?")
                    }
                case whileExpr: WhileExpr => buildBlockAccessLink(whileExpr.block, blockRecords)
                case _ => ()
            }
        }
    }

    public func debugPrint(): Unit {
        printAccessLinks()
    }

    private func printAccessLinks(): Unit {
        println("======= Access Links =======")

        for ((node, record) in this.accessLinkMap) {
            printActivationRecord(record)
            println("----------------------------")
        }
    }

    private func printActivationRecord(record: ActivationRecords): Unit {
        var curOpt: ?ActivationRecords = Some(record)
        var level: Int = 0

        while (let Some(cur) <- curOpt) {
            let nameStr = match (cur.name) {
                case Some(n) => n
                case None => "<block>"
            }

            println(nameStr)

            curOpt = cur.accessLink
            level += 1
        }
    }

    private func repeatString(s: String, n: Int): String {
        var out: String = ""
        for (i in 0..n) {
            out = out + s
        }
        out
    }
}
