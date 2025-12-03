func aaa(): Int64 {
    return 42;
}

func bbb(a: Int64): Int64 {
    return a + 42;
}

func ccc(): Int64 {
    return bbb(aaa());
}

main() {
    var a = aaa;
    a = ccc
}
