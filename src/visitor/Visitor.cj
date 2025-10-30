package cjcj.visitor

public abstract class Visitor<R> {
    protected open func visit(_: Program): R {
        throw Exception("Unimplemented method for Visitor : Program")
    }

    protected open func visit(_: BinaryExpr): R {
        throw Exception("Unimplemented method for Visitor : Binary Expression")
    }

    protected open func visit(_: UnaryExpr): R {
        throw Exception("Unimplemented method for Visitor : Unary Expression")
    }

    protected open func visit(_: ParenExpr): R {
        throw Exception("Unimplemented method for Visitor : Parent Expression")
    }

    protected open func visit(_: LitConstExpr): R {
        throw Exception("Unimplemented method for Visitor : Literal Constant Expression")
    }

    protected open func visit(_: AssignExpr): R {
        throw Exception("Unimplemented method for Visitor : Assign Expression")
    }

    protected open func visit(_: RefExpr): R {
        throw Exception("Unimplemented method for Visitor : Reference Expression")
    }

    protected open func visit(_: Block): R {
        throw Exception("Unimplemented method for Visitor : Block Expression")
    }

    protected open func visit(_: IfExpr): R {
        throw Exception("Unimplemented method for Visitor : If Expression")
    }

    protected open func visit(_: WhileExpr): R {
        throw Exception("Unimplemented method for Visitor : While Expression")
    }

    protected open func visit(_: CallExpr): R {
        throw Exception("Unimplemented method for Visitor : Call Expression")
    }

    protected open func visit(_: ReturnExpr): R {
        throw Exception("Unimplemented method for Visitor : Return Expression")
    }

    protected open func visit(_: JumpExpr): R {
        throw Exception("Unimplemented method for Visitor : Jump Expression")
    }

    protected open func visit(_: VarDecl): R {
        throw Exception("Unimplemented method for Visitor : Variable Declaration")
    }

    protected open func visit(_: FuncParam): R {
        throw Exception("Unimplemented method for Visitor : Function Paramters")
    }

    protected open func visit(_: FuncDecl): R {
        throw Exception("Unimplemented method for Visitor : Function Declaration")
    }

    protected open func visit(_: MainDecl): R {
        throw Exception("Unimplemented method for Visitor : Main Declaration")
    }

    protected open func visit(_: ClassDecl): R {
        throw Exception("Unimplemented method for Visitor : Class Declaration")
    }

    protected open func visit(_: Body): R {
        throw Exception("Unimplemented method for Visitor : Body")
    }

    protected open func visit(_: Argument): R {
        throw Exception("Unimplemented method for Visitor : Argument")
    }

    protected open func visit(_: TypeNode): R {
        throw Exception("Unimplemented method for Visitor : Type Node")
    }

    protected open func visit(_: PrimitiveType): R {
        throw Exception("Unimplemented method for Visitor : Primitive Types")
    }

    protected open func visit(_: RefType): R {
        throw Exception("Unimplemented method for Visitor : Reference Type")
    }

    protected open func visit(_: FuncType): R {
        throw Exception("Unimplemented method for Visitor : Function Type")
    }

    protected open func visit(_: VariableReference): R {
        throw Exception("Unimplemented method for Visitor : Variable Reference (ASG)")
    }

    protected open func visit(_: FuncReference): R {
        throw Exception("Unimplemented method for Visitor : Function Reference (ASG)")
    }

    protected open func visit(_: ClassReference): R {
        throw Exception("Unimplemented method for Visitor : Class Reference (ASG)")
    }

    protected open func visit(_: VarDeclWithRef): R {
        throw Exception("Unimplemented method for Visitor : Variable Declaration with" + "References Stored (ASG)")
    }

    protected open func visit(_: FuncDeclWithRef): R {
        throw Exception("Unimplemented method for Visitor : Function Declaration with" + "References Stored (ASG)")
    }

    protected open func visit(_: MainDeclWithRef): R {
        throw Exception("Unimplemented method for Visitor : Main Declaration with" + "References Stored (ASG)")
    }

    protected open func visit(_: ClassDeclWithRef): R {
        throw Exception("Unimplemented method for Visitor : Class Declaration with" + "References Stored (ASG)")
    }

    protected open func visit(_: MemberAccess): R {
        throw Exception("Unimplemented method for Visitor : Member Access")
    }

    protected open func visit(_: PrimitiveTypeExpr): R {
        throw Exception("Unimplemented method for Visitor : Primitive type expression")
    }

    protected open func visit(_: RefExprWithRef): R {
        throw Exception("Unimplemented method for Visitor : Reference expression with reference")
    }

    protected open func visit(_: ThisSuperExpr): R {
        throw Exception("Unimplemented method for Visitor : This Super expression")
    }

    protected open func visit(_: ThisSuperReference): R {
        throw Exception("Unimplemented method for Visitor : This Super reference")
    }

    protected open func visit(_: CallExprWithRef): R {
        throw Exception("Unimplemented method for Visitor : Call expression with reference")
    }

    protected open func visit(_: MemberAccessWithRef): R {
        throw Exception("Unimplemented method for Visitor : Member access with reference")
    }

    protected open func visit(_: InterfaceDecl): R {
        throw Exception("Unimplemented method for Visitor : Interface Declaration")
    }

    protected open func visit(_: InterfaceDeclWithRef): R {
        throw Exception("Unimplemented method for Visitor : Interface Declaration with reference")
    }

    protected open func visit(_: InterfaceReference): R {
        throw Exception("Unimplemented method for Visitor : Interface Reference")
    }
}

public abstract class DefaultVisitor<R> <: Visitor<R> {
    // public open func merge(a: R, b: R): R {
    //     a
    // }

    // private func fold(col: Collection<R>): R {
    //     col.iterator().fold(default, {acc, entry => merge(acc, entry)})
    // }

    public DefaultVisitor(private let default: R) {
    }

    public open override func visit(program: Program): R {
        program.decls.iterator().forEach({decl => decl.traverse(this)})
        default
    }

    public open override func visit(binaryExpr: BinaryExpr): R {
        binaryExpr.left.traverse(this)
        binaryExpr.right.traverse(this)
    }

    public open override func visit(unaryExpr: UnaryExpr): R {
        unaryExpr.right.traverse(this)
    }

    public open override func visit(parenExpr: ParenExpr): R {
        parenExpr.parenthesizedExpr.traverse(this)
    }

    public open override func visit(_: LitConstExpr): R {
        default
    }

    public open override func visit(assignExpr: AssignExpr): R {
        assignExpr.right.traverse(this)
    }

    public open override func visit(_: RefExpr): R {
        default
    }

    public open override func visit(block: Block): R {
        block.nodes.iterator().forEach({node => node.traverse(this)})
        default
    }

    public open override func visit(ifExpr: IfExpr): R {
        ifExpr.elseBranch.traverse(this)
        ifExpr.condition.traverse(this)
        ifExpr.ifBlock.traverse(this)
    }

    public open override func visit(whileExpr: WhileExpr): R {
        whileExpr.block.traverse(this)
        whileExpr.condition.traverse(this)
    }

    public open override func visit(callExpr: CallExpr): R {
        callExpr.arguments.iterator().forEach({
            arg => arg.traverse(this)
        })

        callExpr.callee.traverse(this)
    }

    public open override func visit(returnExpr: ReturnExpr): R {
        match (returnExpr.expr) {
            case Some(expr) => expr.traverse(this)
            case _ => default
        }
    }

    public open override func visit(_: JumpExpr): R {
        default
    }

    public open override func visit(varDecl: VarDecl): R {
        if (let Some(initzer) <- varDecl.initializer) {
            initzer.traverse(this)
        }

        if (let Some(declType) <- varDecl.declType) {
            declType.traverse(this)
        }
        default
    }

    public open override func visit(funcParam: FuncParam): R {
        funcParam.paramType.traverse(this)
    }

    public open override func visit(funcDecl: FuncDecl): R {
        if (let Some(declType) <- funcDecl.declType) {
            declType.traverse(this)
        }

        if (let Some(realBlock) <- funcDecl.block) {
            realBlock.traverse(this)
        }
        default
    }

    public open override func visit(mainDecl: MainDecl): R {
        if (let Some(declType) <- mainDecl.declType) {
            declType.traverse(this)
        }

        mainDecl.block.traverse(this)
    }

    public open override func visit(classDecl: ClassDecl): R {
        classDecl.superTypes.iterator().forEach({superType => superType.traverse(this)})
        classDecl.body.traverse(this)
    }

    public open override func visit(body: Body): R {
        body.decls.iterator().forEach({
            decl => decl.traverse(this)
        })
        default
    }

    public open override func visit(argument: Argument): R {
        argument.expr.traverse(this)
    }

    public open override func visit(_: TypeNode): R {
        default
    }

    public open override func visit(_: PrimitiveType): R {
        default
    }

    public open override func visit(_: RefType): R {
        default
    }

    public open override func visit(_: VariableReference): R {
        default
    }

    public open override func visit(_: FuncReference): R {
        default
    }

    public open override func visit(_: ClassReference): R {
        default
    }

    public open override func visit(_: InterfaceReference): R {
        default
    }

    public open override func visit(varDecl: VarDeclWithRef): R {
        if (let Some(initzer) <- varDecl.initializer) {
            initzer.traverse(this)
        }

        if (let Some(declType) <- varDecl.declType) {
            declType.traverse(this)
        }
        default
    }

    public open override func visit(funcDecl: FuncDeclWithRef): R {
        if (let Some(declType) <- funcDecl.declType) {
            declType.traverse(this)
        }

        if (let Some(realBlock) <- funcDecl.block) {
            realBlock.traverse(this)
        }
        default
    }

    public open override func visit(mainDecl: MainDeclWithRef): R {
        if (let Some(declType) <- mainDecl.declType) {
            declType.traverse(this)
        }

        mainDecl.block.traverse(this)
    }

    public open override func visit(classDecl: ClassDeclWithRef): R {
        classDecl.superTypes.iterator().forEach({superType => superType.traverse(this)})
        classDecl.body.traverse(this)
    }

    public open override func visit(memberAccess: MemberAccess): R {
        memberAccess.baseExpr.traverse(this)
    }

    public open override func visit(memberAccess: MemberAccessWithRef): R {
        memberAccess.baseExpr.traverse(this)
    }

    public open override func visit(_: PrimitiveTypeExpr): R {
        default
    }

    public open override func visit(refExpr: RefExprWithRef): R {
        refExpr.ref.getOrThrow().traverse(this)
    }

    public open override func visit(_: ThisSuperExpr): R {
        default
    }

    public open override func visit(_: ThisSuperReference): R {
        default
    }

    public open override func visit(callExpr: CallExprWithRef): R {
        callExpr.arguments.iterator().forEach({
            arg => arg.traverse(this)
        })

        callExpr.callee.traverse(this)
    }

    public open override func visit(interfaceDecl: InterfaceDecl): R {
        interfaceDecl.superTypes.iterator().forEach({superType => superType.traverse(this)})
        interfaceDecl.body.traverse(this)
    }

    public open override func visit(interfaceDecl: InterfaceDeclWithRef): R {
        interfaceDecl.superTypes.iterator().forEach({superType => superType.traverse(this)})
        interfaceDecl.body.traverse(this)
    }
}
