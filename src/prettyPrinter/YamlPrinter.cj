package cjcj.prettyPrinter

public interface YamlPrintable {
    func yamlPrint(printer: YamlPrinter): Unit
}

public class YamlPrinter {
    private var indentation: Int64 = 0
    private let printer: PrettyPrinter = PrettyPrinter(tabSize: 2)
    private var atObjectStart: Bool = true
    private var atListItemStart: Bool = false

    private func printlnIfNeeded(): Unit {
        if (atObjectStart) {
            atObjectStart = false
            if (atListItemStart) {
                atListItemStart = false
                printer.indent()
            }
        } else {
            printer.append("\n")
        }
    }

    public func printObject(key: String, obj: YamlPrintable): Unit {
        printlnIfNeeded()
        printer.append(key + ":")
        printer.indent()
        printer.append("\n")
        atObjectStart = true
        obj.yamlPrint(this)
        atObjectStart = false
        printer.unindent()
    }

    public func printOptionalObject<T>(key: String, obj: ?T): Unit where T <: YamlPrintable {
        if (let Some(o) <- obj) {
            printObject(key, o)
        } else {
            printlnIfNeeded()
            printer.append(key + ": null")
        }
    }

    public func printList<T>(key: String, objs: Iterable<T>): Unit where T <: YamlPrintable {
        printlnIfNeeded()
        if (objs.iterator().isEmpty()) {
            printer.append(key + ": []")
            return
        }
        printer.append(key + ":")
        objs.iterator().forEach(
            {
                o =>
                    printer.append("\n- ")
                    atObjectStart = true
                    atListItemStart = true
                    o.yamlPrint(this)
                    if (atListItemStart) {
                        printer.append("{}")
                        atListItemStart = false
                    } else {
                        printer.unindent()
                    }
                    atObjectStart = false
            }
        )
    }

    public func print(key: String, value: ToString): Unit {
        printlnIfNeeded()
        printer.append(key + ": " + value.toString())
    }

    public func toString(): String {
        printer.toString()
    }
}
