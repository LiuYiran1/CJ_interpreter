main() {
    let x = 42
    func middle(): Unit {
        func inner1(): Unit {
            println(x) // prints 42
        }
        func inner2(): Unit {
            println(y) // Error at line 8: [UNDEFINED_VAR]: y is not defined
        }
        let x = 2
        let y = 100
        println(x) // prints 2
        inner1()
        inner2()
    }
    middle()
}
