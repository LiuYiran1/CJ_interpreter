package cjcj.visitor

import std.collection.*

public class Type <: Equatable<Type> & Hashable {
    public static let DUMMY = Type("")
    public static let ANY: Type = Type("Any", ArrayList(), true, 0)
    public static let NOTHING: Type = Type("Nothing", ArrayList([ANY]), false, 1)
    public static let UNIT: Type = Type("Unit", ArrayList([ANY]), false, 1)

    private let parents_: ArrayList<Type>
    private let name_: String
    private let isOpen_: Bool
    private let rootDist_: Int64

    // Every type is a subtype of any.
    public init(name: String) {
        this(name, ArrayList())
    }

    public init(name: String, parents: ArrayList<Type>) {
        this(name, parents, false)
    }

    public init(name: String, parents: ArrayList<Type>, isOpen: Bool) {
        this(name, parents, isOpen, min(parents.iterator().map({p => p.rootDist})).getOrDefault({=> 0}) + 1)
    }

    private init(name: String, parents: ArrayList<Type>, isOpen: Bool, rootDist: Int64) {
        name_ = name
        parents_ = parents
        isOpen_ = isOpen
        rootDist_ = rootDist
        checkOpenParents()
    }

    public init(name: String, parents: Array<Type>) {
        this(name, parents, false)
    }

    public init(name: String, parents: Array<Type>, isOpen: Bool) {
        this(name, parents, isOpen, min(parents.iterator().map({p => p.rootDist})).getOrThrow({
            => Exception("Parents cannot be empty")
        }) + 1)
    }

    private init(name: String, parents: Array<Type>, isOpen: Bool, rootDist: Int64) {
        name_ = name
        parents_ = parents.iterator().fold(
            ArrayList(),
            {
                r, t =>
                    r.add(t);
                    r
            }
        )
        isOpen_ = isOpen
        rootDist_ = rootDist
        checkOpenParents()
    }

    private func checkOpenParents(): Unit {
        parents.iterator().forEach({
            p => if (!p.isOpen) {
                // TODO: For error handling we can print them all.
                throw Exception("Parent: ${p.name} is not inheritable")
            }
        })
    }

    public prop name: String {
        get() {
            name_
        }
    }

    public prop parents: ArrayList<Type> {
        get() {
            parents_
        }
    }

    public prop isOpen: Bool {
        get() {
            isOpen_
        }
    }

    public prop ancestors: Array<Type> {
        get() {
            ancestorsUntil(ANY).getOrThrow({
                => Exception("Impossible, couldn't find ANY in " + "the ancestors of ${this.name}")
            })
        }
    }

    public prop ancestorSet: HashSet<Type> {
        get() {
            HashSet(ancestors)
        }
    }

    public prop rootDist: Int64 {
        get() {
            rootDist_
        }
    }

    public func isParent(other: Type): Bool {
        if (other == NOTHING) {
            return true
        }
        other.ancestorsUntil(this).isSome()
    }

    /*
     * Performs a BFS starting from "this" and visits all the parents until "target" is find.
     * We can cache the visits in the future to improve the performance.
     * Returns the list of ancestors including "this" type up to a given target type. If the target
     * is not found returns None. The list is ordered by distance (in number of edges) from "this".
     */
    private func ancestorsUntil(target: Type): ?Array<Type> {
        let q: Queue<Type> = ArrayQueue()
        let visited: Set<Type> = HashSet()
        let res: ArrayList<Type> = ArrayList()
        visited.add(this)
        res.add(this)
        q.add(this)
        while (let Some(front) <- q.remove()) {
            if (front == target) {
                return res.toArray()
            }
            if (front.rootDist < target.rootDist) {
                return None
            }
            front.parents.iterator().filter({p => !visited.contains(p) && p.rootDist >= target.rootDist}).forEach(
                {
                    p =>
                        visited.add(p);
                        res.add(p);
                        q.add(p)
                }
            )
        }
        None
    }

    public override func hashCode(): Int64 {
        name.hashCode()
    }

    public operator override func ==(other: Type): Bool {
        name == other.name
    }

    public operator override func !=(other: Type): Bool {
        !(this == other)
    }
}
