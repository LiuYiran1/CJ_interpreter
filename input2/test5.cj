let immut = initImmut()
var counter = 0

func initImmut(): Int64 {
    var ans = 0
    var x = 0
    while (x < 10) {
        ans = x + ans
        x = x + 1
    }
    ans
}

func increment(): Unit {
    counter = counter + 1
}

main() {
    println(immut)
    increment()
    increment()
    counter
}
