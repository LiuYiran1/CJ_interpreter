package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.*

// *************************** 构建accessLink + 将函数的参数的Record加入到函数的items中 + 检查函数的定义问题 ***************************

class UnhandledDeclInAccessLinkBuilder <: Exception {
    public UnhandledDeclInAccessLinkBuilder(let fromWhere: Node) {}

    public override func toString(): String {
        "AccessLinkBuilder Exception at line ${getPosition(fromWhere).line}" // [10..] removes "ErrorCode."
    }
}

public class AccessLinkBuilder {
    var accessLinkMap: Map<Node, ActivationRecords> = HashMap<Node, ActivationRecords>();
    var tabNum = 0
    var curRecords: ?ActivationRecords = None

    public func buildAccessLink(program: Program): Map<Node, ActivationRecords> { // 返回每个block及其对应的活动记录
        var globalRecords: ActivationRecords = BlockActivationRecords("Global", None);

        accessLinkMap.add(program, globalRecords);

        for (decl in program.decls) {
            match (decl) {
                case mainDecl: MainDecl =>
                    var mainRecord: Record = Record(mainDecl.identifier, None, mainDecl.declType, mainDecl.keyword,
                        mainDecl);
                    globalRecords.addRecord(mainDecl.identifier.value, mainRecord, mainDecl);
                    buildMainAccessLink(mainDecl, globalRecords);
                case funcDecl: FuncDecl =>
                    var funcRecord: Record = Record(funcDecl.identifier, None, funcDecl.declType, funcDecl.keyword,
                        funcDecl);
                    globalRecords.addRecord(funcDecl.identifier.value, funcRecord, funcDecl);
                    buildFuncAccessLink(funcDecl, globalRecords);
                case varDecl: VarDecl => () // TODO:全局变量
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
            // 处理函数的参数
            let params = funcDecl.params
            for (param in params) {
                var paramName = param.name.value
                var paramRecord: Record = Record(param.identifier, None, Some(param.paramType), param.keyword, param)
                funcRecords.addRecord(paramName, paramRecord, funcDecl)
            }

            // 处理函数内部的声明
            buildBlockAccessLink(theBlock, funcRecords);
        } else {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.FUNC_MISSING_BODY, "函数定义中缺少函数体。", funcDecl);
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
                case funcDecl: FuncDecl =>
                    var funcRecord: Record = Record(funcDecl.identifier, None, None, funcDecl.keyword, funcDecl);
                    blockRecords.addRecord(funcDecl.identifier.value, funcRecord, funcDecl);
                    buildFuncAccessLink(funcDecl, blockRecords);
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
