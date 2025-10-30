package cjcj.visitor

import std.collection.Map
import std.collection.HashMap

/*
 * Defines an Environment in which you can associate keys to values. Each environment knows who was
 * before him and is able to provide values' references by going up the cactus.
 * (From every environment there's only one way to the global one)
 */
public class Environment<K, V> where K <: Hashable & Equatable<K> & ToString {
    private var enclosing_: ?Environment<K, V>
    private let elements_: Map<K, V> = HashMap()

    public init(enclosing: ?Environment<K, V>) {
        enclosing_ = enclosing
    }

    public init() {
        this(None)
    }

    /*
     * Looks for the identifier in this and all parent environments.
     */
    public func getGlobal(key: K): ?V {
        if (let Some(local) <- getLocal(key)) {
            return local
        }
        if (let Some(enc) <- enclosing) {
            return enc.getGlobal(key)
        }
        None
    }

    public func getLocal(key: K): ?V {
        elements.get(key)
    }

    public func declare(key: K, value: V): Unit {
        if (let Some(prev) <- elements.addIfAbsent(key, value)) {
            throw Exception("Multiple declaration of ${key.toString()}")
        }
    }

    public mut prop enclosing: ?Environment<K, V> {
        get() {
            enclosing_
        }
        set(v) {
            enclosing_ = v
        }
    }

    public prop isGlobal: Bool {
        get() {
            enclosing.isNone()
        }
    }

    public prop elements: Map<K, V> {
        get() {
            elements_
        }
    }
}
