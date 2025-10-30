package cjcj.executor

import cjcj.visitor.*

public class Executor {
    // In lab 1, you don't need to handle function declarations and calls.
    // So we provide a very simple evaluation function here that only executes the `main` block.
    private func lab1SimpleEvaluation(program: Program): Int64 {
        let mainDecl = (program
            .decls
            .iterator()
            .filter({it => it is MainDecl})
            .first()
            .getOrThrow() as MainDecl)
            .getOrThrow()
        let evaluator = Evaluator()

        try {
            let val = evaluator.visit(mainDecl.block)
            println(val.toValueString())
            0
        } catch (e: CjcjRuntimeErrorWithLocation) {
            eprintln(e)
            1
        } catch (e: Exception) {
            // This is not expected to happen. There should be no exceptions falling into this branch at the time of the last commit.
            eprintln("\n\n!!! unhandled exception !!!")
            eprintln(e.toString())
            e.printStackTrace()
            1
        }
    }

    public func execute(program: Program): Int64 {
        lab1SimpleEvaluation(program)
    }
}
