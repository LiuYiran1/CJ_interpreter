package cjcj

import cjcj.visitor.Program
import cjcj.parser.*
import cjcj.scanner.*
import cjcj.prettyPrinter.YamlPrinter
import cjcj.executor.Executor
import std.env.*
import std.fs.File

public class Cj {
    static var hadError: Bool = false

    public static func getCodeFromFile(path: String): String {
        File.readFrom(path) |> String.fromUtf8
    }

    public static func getCodeFromStdin(): String {
        getStdIn().readToEnd().getOrThrow()
    }

    public static func parseProgram(source: String): ?Program {
        let scanner = Scanner(source.toRuneArray())
        let tokens = scanner.scanTokens().toArray()

        let parser: Parser = Parser(tokens.toArray(), Reporter(getStdErr(), tokens.toArray()))
        let program: ?Program = parser.parse()
        parser.logErrors()

        program
    }

    public static func printAst(source: String): Unit {
        if (let Some(p) <- parseProgram(source)) {
            let yamlPrinter: YamlPrinter = YamlPrinter()
            p.yamlPrint(yamlPrinter)
            println(yamlPrinter.toString())
        } else {
            exit(65)
        }
    }

    public static func runCode(source: String): Unit {
        if (let Some(p) <- parseProgram(source)) {
            let executor = Executor()
            exit(executor.execute(p))
        } else {
            exit(65)
        }
    }
}

func printHelp() {
    println("Usage: cjcj [options] [file?]")
    println("Options:")
    println("  run        Run the source code")
    println("  ast        Print the AST of the source code in YAML format. This might be helpful for debugging.")
    println("")
    println("If no file is provided, the interpreter reads from standard input.")
}

main(args: Array<String>) {
    if (args.size == 0) {
        printHelp()
        exit(0)
    }
    match (args[0]) {
        case "run" => Cj.runCode(getCode(args))
        case "ast" => Cj.printAst(getCode(args))
        case _ => printHelp()
    }
}

func getCode(args: Array<String>): String {
    if (args.size == 1) {
        Cj.getCodeFromStdin()
    } else {
        Cj.getCodeFromFile(args[1])
    }
}
