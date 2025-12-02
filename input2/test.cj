func fib(n: Int64): Int64 {
    if (n <= 1) {
        n
    } else {
        fib(n - 1) + fib(n - 2)
    }
}

main() {
    println(fib(4))
    println(fib(6))
    println(fib(8))
}
