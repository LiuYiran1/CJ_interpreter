main() {
    var a = 1
    var b = 1
    var i = 0
    while (i < 10) {
        let c = a
        a = a + b
        b = c
        i = i + 1
    }
    b
}