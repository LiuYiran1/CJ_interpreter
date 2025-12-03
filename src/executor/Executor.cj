package cjcj.executor

import cjcj.visitor.*
import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.*

public class Executor {
    // private func lab1SimpleEvaluation(program: Program): Int64 {
    //     let mainDecl = (program
    //         .decls
    //         .iterator()
    //         .filter({it => it is MainDecl})
    //         .first()
    //         .getOrThrow() as MainDecl)
    //         .getOrThrow()
    //     let evaluator = Evaluator()

    //     try {
    //         let val = evaluator.visit(mainDecl.block)
    //         println(val.toValueString())
    //         0
    //     } catch (e: CjcjRuntimeErrorWithLocation) {
    //         eprintln(e)
    //         1
    //     } catch (e: Exception) {
    //         // This is not expected to happen. There should be no exceptions falling into this branch at the time of the last commit.
    //         eprintln("\n\n!!! unhandled exception !!!")
    //         eprintln(e.toString())
    //         e.printStackTrace()
    //         1
    //     }
    // }

    private func buildAccessLink(program: Program): Map<Node, ActivationRecords> {
        let linkBuilder = AccessLinkBuilder()
        var recordsMap = linkBuilder.buildAccessLink(program)
        linkBuilder.debugPrint()
        return recordsMap
    }

    private func lab2SimpleEvaluation(program: Program): Int64 {
        try {
            // 1. 构建 Evaluator
            let evaluator = Evaluator(buildAccessLink(program), program)

            // 2. 直接访问 program 节点
            // 所有的全局变量初始化、函数注册、Main查找与执行，都封装在 Evaluator.visit(Program) 中
            let val = evaluator.visit(program)

            println(val.toValueString())
            return 0
        } catch (e: CjcjRuntimeErrorWithLocation) {
            eprintln(e)
            return 1
        } catch (e: ReturnException) {
            // 如果 main 中有 return 语句抛出异常
            println(e.returnValue.toValueString())
            return 0
        } catch (e: Exception) {
            eprintln("\n\n!!! unhandled exception !!!")
            eprintln(e.toString())
            e.printStackTrace()
            return 1
        }
    }

    public func execute(program: Program): Int64 {
        lab2SimpleEvaluation(program)
    }
}
