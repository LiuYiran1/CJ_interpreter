main() {
    let x = 10
    func getClosure(): () -> Int64 {
        func closure(): Int64 {
            x * 2
        }
        closure
    }
    getClosure()()
}
