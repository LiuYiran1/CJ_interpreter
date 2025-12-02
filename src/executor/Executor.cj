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
        let mainDecl = (program
            .decls
            .iterator()
            .filter({it => it is MainDecl})
            .first()
            .getOrThrow() as MainDecl)
            .getOrThrow()

        // try {
            let evaluator = Evaluator(buildAccessLink(program), program)
            let val = evaluator.visit(mainDecl.block)
            println(val.toValueString())
            0
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
    }

    public func execute(program: Program): Int64 {
        lab2SimpleEvaluation(program)
    }
}
