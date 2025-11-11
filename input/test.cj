main() {
    var counter = 0
    var output = "计数过程: "
    
    while (counter < 5) {
        var temp_str = "步骤" + counter.toString() + ": "
        
        if (counter % 2 == 0) {
            temp_str = temp_str + "偶数"
        } else {
            temp_str = temp_str + "奇数"
        }
        
        output = output + temp_str + " "
        counter = counter + 1
    }
    
    output
}