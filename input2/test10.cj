var G = 100

func outer(): Unit {
    let b = 20 // 不可变（let）
    func inner(): Uint {
        b
        G
        a
    }
    inner()
}

func afterOuter(): Unit {
    func inner2(): Uint {
        println(e) // 应触发 UNDEFINED_VAR（因为 inner2 定义时没有捕获 e）
    }
    inner2()
    var e = 5
}

main() {
    var a = 10 // 可变（var），非全局
    outer()
    afterOuter()
}
