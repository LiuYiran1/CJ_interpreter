main() {
    var x = 10
    func inner(): Int64 {
        x * 2
        if (1 == 1) {
            x = 1
        } else {
            x = 2
        }
    }
    if (1 == 1) {
        x = 1
    } else {
        x = 2
    }
    inner()
}
