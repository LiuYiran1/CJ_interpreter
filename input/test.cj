main() {
    var fib1 = 1
    var fib2 = 1
    var count = 0
    var result = 0

    while (count < 10) {
        if (count % 2 == 0) {
            result = fib1
            fib1 = fib1 + fib2
        } else {
            result = fib2
            fib2 = fib1 + fib2
        }

        if (result > 100) {
            break
        }

        count = count + 1
    }

    println(result)
    0
}
