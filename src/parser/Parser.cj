package cjcj.parser

import cjcj.visitor.*
import cjcj.scanner.Token
import cjcj.scanner.TokenKind
import std.collection.ArrayList

public class Parser {
    private let declParser: DeclParser
    private let parserHelper: ParserHelper

    public Parser(private let tokens: Array<Token>, public let reporter: Reporter) {
        this.parserHelper = ParserHelper(tokens, reporter)
        this.declParser = DeclParser(parserHelper, reporter)
    }

    public func parse(): ?Program {
        try {
            var nodes: ArrayList<Decl> = ArrayList()
            parserHelper.endStar()

            while (!parserHelper.check(TokenKind.MAIN) && !parserHelper.isAtEnd()) {
                if (let Some(obj) <- declParser.topLevelObject()) {
                    nodes.add(obj)
                    parserHelper.endPlus("Expected end of TopLevelObject", parserHelper.peek(), parserHelper.current)
                } else {
                    parserHelper.error(parserHelper.peek(), "Expected TopLevelObject keyword", parserHelper.current)
                    parserHelper.synchronize()
                }
            }
            if (let Some(obj) <- declParser.mainDefinition()) {
                nodes.add(obj)
            } else {
                parserHelper.error(parserHelper.peek(), "Program needs at least 1 main declaration",
                    parserHelper.current)
            }
            parserHelper.endPlus("Expected end of main declaration", parserHelper.peek(), parserHelper.current)
            while (!parserHelper.isAtEnd()) {
                if (let Some(obj) <- declParser.topLevelObject()) {
                    nodes.add(obj)
                    parserHelper.endPlus("Expected end of TopLevelObject", parserHelper.peek(), parserHelper.current)
                } else if (parserHelper.check(TokenKind.MAIN)) {
                    parserHelper.error(parserHelper.peek(), "Program can have at most 1 main declaration",
                        parserHelper.current)
                    nodes.add(declParser.mainDefinition().getOrThrow())

                    parserHelper.endPlus("Expected end of main declaration", parserHelper.peek(), parserHelper.current)
                } else {
                    parserHelper.error(parserHelper.peek(), "Expected TopLevelObject keyword", parserHelper.current)
                    parserHelper.synchronize()
                }
            }
            if (reporter.empty) {
                return Program(NodeIdManager.nextId(), nodes)
            } else {
                return None
            }
        } catch (_) {
            return None
        }
    }

    public func logErrors() {
        parserHelper.logErrors()
    }
}
