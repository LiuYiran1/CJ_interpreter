package cjcj.test

import cjcj.visitor.*
import cjcj.parser
import cjcj.scanner.*
import std.env.*
import std.collection.ArrayList

@Test
class ParserTests {
    private func scan(test: String): Array<Token> {
        Scanner(test.toRuneArray()).scanTokens().toArray()
    }

    private func parse(test: String): ?Program {
        let tokens: Array<Token> = scan(test)
        parser.Parser(tokens, parser.Reporter(getStdErr(), tokens)).parse()
    }

    private func getMain(test: String): MainDecl {
        let program = parse(test)
        @Assert(program.isSome())
        for (d in program.getOrThrow().decls) {
            if (let Some(m) <- (d as MainDecl)) {
                return m
            }
        }
        throw Exception("No main inside program")
    }

    @TestCase
    func mainDecl_test() {
        let test: String = """
            main(): Unit{
            }"""

        getMain(test)
    }

    @TestCase
    func mainDeclTooManyParams_test() {
        let test: String = """
            main(a: Int64, b: String): Unit{
            }"""

        @Assert(parse(test).isNone())
    }

    @TestCase
    func funcDecl_test() {
        let test: String = """
            main(){
                func a() {
                }
            }"""

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is FuncDecl }))
    }

    @TestCase
    func funcDeclParams_test() {
        let test: String = """
            class CustomType {
            }
            main(){
                func a(a: Int64, b: Unit, c: CustomType) {
                }
            }
            """

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is FuncDecl }))
        let decl: FuncDecl = (m.block.nodes[0] as FuncDecl).getOrThrow()
        @Assert(decl.params.size == 3)
    }

    @TestCase
    func funcDeclDeclType_test() {
        let test: String = """
            main(){
                func a(): Int64 {
                }
            }"""

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is FuncDecl }))
        let decl: FuncDecl = (m.block.nodes[0] as FuncDecl).getOrThrow()
        @Assert(decl.declType.isSome())
    }

    @TestCase
    func funcDeclBlock_test() {
        let test: String = """
            func f() {
            }
            main(){
                func a() {
                    let test = 3986
                    var b: String = "string"
                    while (test == 5) {
                        f()
                    }
                    if (true) {
                        return 9
                    }
                    return 6347
                }
            }
            """

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is FuncDecl }))
        let decl: FuncDecl = (m.block.nodes[0] as FuncDecl).getOrThrow()
        @Assert(decl.block.getOrThrow().nodes.size == 5)
    }

    @TestCase
    func funcDeclGeneral_test() {
        let test: String = """
            class CustomType {
            }
            main(){
                func a(a: Int64, b: Unit, c: CustomType): Int64 {
                    let bo = 5
                    if (bo == 7) {
                        return 4
                    }
                    return 10
                }
            }"""

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is FuncDecl }))
        let decl: FuncDecl = (m.block.nodes[0] as FuncDecl).getOrThrow()
        @Assert(decl.declType.isSome())
        @Assert(decl.params.size == 3)
        @Assert(decl.block.getOrThrow().nodes.size == 3)
    }

    @TestCase
    func classDecl_test() {
        let test: String = """
            class a {
            }
            main(){
            }"""

        let p: ?Program = parse(test)
        @Assert(p.isSome())
        let program = p.getOrThrow()
        @Assert(program.decls[0] is ClassDecl)
    }

    @TestCase
    func classDeclWithSupertypes_test() {
        let test: String = """
            class a <: b & c & d {
            }
            class b {
            }
            class c {
            }
            class d {
            }
            main(){
            }"""

        let p: ?Program = parse(test)
        @Assert(p.isSome())
        let program = p.getOrThrow()
        @Assert(program.decls[0] is ClassDecl)
        let classDecl = (program.decls[0] as ClassDecl).getOrThrow()
        @Assert(classDecl.superTypes.size == 3)
    }

    @TestCase
    func classDeclBody_test() {
        let test: String = """
            class a {
                let a = 6
                let b: Int64 = 347
                func c() {
                }
                init(a: CustomType) {
                }
            }
            class CustomType {
            }
            main(){
            }"""

        let p: ?Program = parse(test)
        @Assert(p.isSome())
        let program = p.getOrThrow()
        @Assert(program.decls[0] is ClassDecl)
        let classDecl = (program.decls[0] as ClassDecl).getOrThrow()
        @Assert(classDecl.body.decls.size == 4)
    }

    @TestCase
    func varDecl_test() {
        let test: String = """
            main(){
                let a: Int32
                let b: Int64 = 567
                var c: Int32
                var d = 567
            }"""

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is VarDecl }))
        let decls: ArrayList<VarDecl> = m.block.nodes.iterator().map({n => (n as VarDecl).getOrThrow()}).fold(
            ArrayList(),
            {
                res, decl =>
                    res.add(decl);
                    res
            }
        )
        @Expect(decls[0].initializer.isNone())
        @Expect(decls[1].initializer.isSome())
        @Expect(decls[2].initializer.isNone())
        @Expect(decls[3].initializer.isSome())

        @Expect(decls[0].declType.isSome())
        @Expect(decls[1].declType.isSome())
        @Expect(decls[2].declType.isSome())
        @Expect(decls[3].declType.isNone())

        @Expect(decls[0].keyword.kind == TokenKind.LET)
        @Expect(decls[1].keyword.kind == TokenKind.LET)
        @Expect(decls[2].keyword.kind == TokenKind.VAR)
        @Expect(decls[3].keyword.kind == TokenKind.VAR)
    }

    @TestCase
    func binaryExpr_test() {
        let test: String = """
            main(){
                1 + 5
                1 - 5
                1 * 5
                1 / 5
                1 ** 5
            }"""

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is BinaryExpr }))
    }

    @TestCase
    func unaryExpr_test() {
        let test: String = """
            main(){
                -134
                !134
            }"""

        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is UnaryExpr }))
    }

    @TestCase
    func parenExpr_test() {
        let test: String = """
            let a = 2
            main(){
                (-134)
                (134 + (5486 - 12) + a)
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is ParenExpr }))
    }

    @TestCase
    func litConstExpr_test() {
        let test: String = """
            main(){
                1231
                "string"
                ()
                1.2
                true
                false
                r'a'
                b'1'
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is LitConstExpr }))
    }

    @TestCase
    func assignExpr_test() {
        let test: String = """
            var a: Int64 = 1
            var b: Int64 = 2
            main(){
                a = 1231 + 8735
                b = a
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is AssignExpr }))
    }

    @TestCase
    func refExpr_test() {
        let test: String = """
            let identifier = 1
            main(){
                identifier
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is RefExpr }))
    }

    @TestCase
    func ifExpr_test() {
        let test: String = """
            main(){
                if (1 == 2) {
                    1
                } else if (1 == 3) {
                    2
                } else {
                    3
                }
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is IfExpr }))
    }

    @TestCase
    func ifExprDesugar_test() {
        let test: String = """
            main(){
                if (1 == 2) {
                    1
                }
            }"""
        // Should add the else branch while parsing.
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is IfExpr }))
    }

    @TestCase
    func whileExpr_test() {
        let test: String = """
            main(){
                while (1 == 2) {
                    1
                }
            }"""
        // Should add the else branch while parsing.
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is WhileExpr }))
    }

    @TestCase
    func callExpr_test() {
        let test: String = """
            func a() {
            }
            main(){
                a()
            }"""
        // Should add the else branch while parsing.
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is CallExpr }))
    }

    @TestCase
    func returnExpr_test() {
        let test: String = """
            main(){
                return 1
            }"""
        // Should add the else branch while parsing.
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is ReturnExpr }))
    }

    // The following tests will be added after the change to the return expression.
    @TestCase
    func returnExprNoExpression_test() {
        let test: String = """
            main(){
                return
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is ReturnExpr }))
    }

    @TestCase
    func returnExprUnitFunc_test() {
        let test: String = """
            let a = 1
            main(): Unit{
                return a
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is ReturnExpr }))
    }

    @TestCase
    func jumpExpr_test() {
        let test: String = """
            main(){
                break
                continue
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is JumpExpr }))
    }

    @TestCase
    func memberAccess_test() {
        let test: String = """
            class B {
                let f = 1
                func c() {
                    B()
                }
            }
            class A {
                let b: B = B()
            }
            let a: A = A()
            func c() {
                A()
            }
            main(){
                a.b.c().f
                c().b
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is MemberAccess }))
    }

    @TestCase
    func primitiveTypeExpr_test() {
        let test: String = """
            main(){
                Int64
                Unit
            }"""
        let m: MainDecl = getMain(test)
        @Assert(m.block.nodes.iterator().all({ n => n is PrimitiveTypeExpr }))
    }

    @TestCase
    func thisSuperExpr_test() {
        let test: String = """
            class A {
                func a() {
                    return this
                }
            }
            main(){
            }"""
        @Assert(parse(test).isSome())
    }

    @TestCase
    func general_test() {
        let test: String = """
            main(args: Bp){
                let a: Int32
                func A (a: Type, b: Type, c: Type){
                    a = 1
                    b = a + c

                    if(true) {
                        return a;
                    } else {
                    }
                    
                    return a;

                    a + b
                }

                a = if(true) {
                    2
                } else if( boolean == 2 ) {
                    "test-string"
                } else {
                    A()
                }

                let b = a + a

                a = 3
                a = 5.2
                a = (a * c + (d - e)) ** 3

                A()
                A(1, 2, "test-param")
            }
            /*
                Some comment
                3(*&#@71I#(@))))))
            */
            """
        @Assert(parse(test).isSome())
    }
}
