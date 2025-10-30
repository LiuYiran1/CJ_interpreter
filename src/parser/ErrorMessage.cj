package cjcj.parser

public abstract class BaseErrorMessage <: ToString {}

public class Error <: BaseErrorMessage {
    Error(public let line: Int32, public let index: Int64, public let wher: String, public let message: String,
        public let suffixPrefix: (String, String)) {}

    public func toString(): String {
        let lineStr: String = line.toString()
        let spaces: String = " " * lineStr.size
        return """
\u{001b}[31m
error\u{001b}[0m: ${message}
${spaces} |
${lineStr} | ${suffixPrefix[0]}${Reporter
            .redify(wher)} ${suffixPrefix[1]}
${spaces} | ${" " * suffixPrefix[0].size}^
            """
    }
}

public class ErrorUnclosedDelimiter <: BaseErrorMessage {
    ErrorUnclosedDelimiter(public let line: Int32, public let startIndex: Int64, public let start: String,
        public let suffixPrefixStart: (String, String), public let currentIndex: Int64, public let current: String,
        public let suffixPrefixCurrent: (String, String)) {}

    public func toString(): String {
        let lineStr: String = line.toString()
        let spaces: String = " " * lineStr.size
        if (currentIndex - startIndex < 20) {
            return """
\u{001b}[31m
error\u{001b}[0m: unclosed delimiter '${Reporter.redify(start)}'
${spaces} |
${lineStr} | ${suffixPrefixStart[0]}${Reporter
                .redify(start)} ${suffixPrefixStart[1]}
${spaces} | ${" " * suffixPrefixStart[0].size}^ 
                """
        } else {
            return """
\u{001b}[31m
error\u{001b}[0m: unclosed delimiter '${Reporter.redify(start)}'
${spaces} |
${lineStr} | ${suffixPrefixStart[0]}${Reporter
                .redify(start)} ${suffixPrefixStart[1]}
${spaces} | ${" " * suffixPrefixStart[0].size}^
                """
        }
    }
}
