package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.*

class Lab1TodoException <: Exception {
    public init(message: String) {
        super("Lab 1 TODO: " + message)
    }
}

class UnhandledTokenKind <: Exception{
    public init(message: String) {
        super("Unhandled Token Kind: " + message)
    }
}

/** 
 * Evaluator Visitor
 *
 * Lab1 TODO: We have given the simplest form, each `Node` will return a `Value` after evaluation.
 * But is this sufficient? Do you need to add something new to handle ASTs that don't return a value?
 *
 * You may need to modify the member variables and/or generic parameters of the Evaluator class.
 */
public open class Evaluator <: Visitor<Value> {
    // How do you get and set the context when executing an expression?
    // You might need to add some member variables to do this.
    //
    // private let context = ...
    // private let static_scope = ...
    let recordsStack = ArrayStack<ActivationRecords>()
    var curRecords : ?ActivationRecords = None

    public open override func visit(_: Program): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Program")
    }

    // This is just an example of how to implement the visit method for BinaryExpr.
    // You may need to modify, split, or completely rewrite it depending on your design.
    public open override func visit(expr: BinaryExpr): Value {
        let left = expr.left.traverse(this)
        let right = expr.right.traverse(this)
        try {
            match (expr.oper.kind) {
                case TokenKind.ADD => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a + b)
                    case (VString(a), VString(b)) => Value.from(a + b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.ADD_TYPE_MISMATCH,
                        "cannot add left = ${left}, right = ${right}", expr)
                }
                case _ => throw Lab1TodoException("Unimplemented Binary Operator `${expr.oper.kind}`")
            }
        } catch (e: OverflowException) {
            match (e.message) {
                case "add" => throw CjcjRuntimeErrorWithLocation(ErrorCode.ADD_OVERFLOW,
                    "overflow add: left = ${left}, right = ${right}", expr)
                case _ => throw Lab1TodoException("You need to handle overflow of ${e.message}")
            }
        }
    }

    public open override func visit(expr: UnaryExpr): Value {
        throw Lab1TodoException("Unary Expression Evaluation Not Implemented")
    }

    public open override func visit(par: ParenExpr): Value {
        throw Lab1TodoException("Parenthesized Expression Evaluation Not Implemented")
    }

    public open override func visit(lit: LitConstExpr): Value {
        match (lit.literal.kind) {
            case TokenKind.INTEGER_LITERAL => return Value.from(Int64.parse(lit.literal.value))
            case _ => throw UnhandledTokenKind(lit.literal.kind.toString() + " in LitConstExpr");    
        }



    }

    public open override func visit(expr: AssignExpr): Value {
        throw Lab1TodoException("Assignment Expression Evaluation Not Implemented")
    }

    public open override func visit(ref: RefExpr): Value {
        match(ref.identifier.kind){
            case TokenKind.IDENTIFIER => 
                if (let Some(curRecords) <- curRecords) {
                    return curRecords.getRecordValue(ref.identifier.value, ref);
                }else{
                    throw Exception();
                }
            case _ => throw UnhandledTokenKind(ref.identifier.kind.toString() + " in RefExpr");    
        }
    }

    public open override func visit(block: Block): Value {
        // 加入活动记录
        var newRecords : ActivationRecords
        if(recordsStack.isEmpty()){
            newRecords = BlockActivationRecords(None, None, None)
        } else {
            var last = recordsStack.peek()
            newRecords = BlockActivationRecords(None, last, None);
        }
        recordsStack.add(newRecords)
        curRecords = newRecords

        var ret = Value.VUnit
        for (stmt in block.nodes.iterator()) {
            ret = stmt.traverse(this)
        }
        return ret
    }

    public open override func visit(expr: IfExpr): Value {
        throw Lab1TodoException("If Expression Evaluation Not Implemented")
    }

    public open override func visit(expr: WhileExpr): Value {
        throw Lab1TodoException("While Expression Evaluation Not Implemented")
    }

    public open override func visit(call: CallExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Call Expression")
    }

    public open override func visit(_: ReturnExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Return Expression")
    }

    public open override func visit(jmp: JumpExpr): Value {
        throw Lab1TodoException("Jump Expression Evaluation Not Implemented")
    }

    public open override func visit(decl: VarDecl): Value {
        var exp_val : ?Value = None;

        if(let Some(exp) <- decl.initializer){
            match (exp) {
                case b: BinaryExpr => exp_val = b.traverse(this)
                case u: UnaryExpr => exp_val = u.traverse(this)
                case l: LitConstExpr => exp_val = l.traverse(this) // 直接的字面量
                case p: ParenExpr => exp_val = p.traverse(this) // 括号表达式
                case _ => throw UnsupportedException("不支持的 Expr 类型")
            }
        }

        var varName : String = decl.identifier.value;
        var newRecord : Record = Record(decl.identifier, exp_val, decl.declType, decl.keyword, decl);

        if(let Some(curRecords) <- curRecords){
            // 重复定义
            if(curRecords.findInCurRecords(varName)){
                throw CjcjRuntimeErrorWithLocation(ErrorCode.DUPLICATED_DEF, "试图在同一静态作用域内定义同名变量", decl);
            } else {
                curRecords.addRecord(varName, newRecord);
            }
        }

        var ret = Value.VUnit;
        return ret;
    }

    public open override func visit(_: FuncParam): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Paramters")
    }

    public open override func visit(_: FuncDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Declaration")
    }

    public open override func visit(_: MainDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Main Declaration")
    }

    public open override func visit(_: ClassDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Class Declaration")
    }

    public open override func visit(_: Body): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Body")
    }

    public open override func visit(arg: Argument): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Argument")
    }

    public open override func visit(_: TypeNode): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Type Node")
    }

    public open override func visit(_: PrimitiveType): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Primitive Types")
    }

    public open override func visit(_: RefType): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Reference Type")
    }

    public open override func visit(_: VariableReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Variable Reference (ASG)")
    }

    public open override func visit(_: FuncReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Reference (ASG)")
    }

    public open override func visit(_: ClassReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Class Reference (ASG)")
    }

    public open override func visit(_: VarDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Variable Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: FuncDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Function Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: MainDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Main Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: ClassDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Class Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: MemberAccess): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Member Access")
    }

    public open override func visit(_: PrimitiveTypeExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Primitive type expression")
    }

    public open override func visit(_: RefExprWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Reference expression with reference")
    }

    public open override func visit(_: ThisSuperExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : This Super expression")
    }

    public open override func visit(_: ThisSuperReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : This Super reference")
    }

    public open override func visit(_: CallExprWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Call expression with reference")
    }

    public open override func visit(_: MemberAccessWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Member access with reference")
    }

    public open override func visit(_: InterfaceDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Declaration")
    }

    public open override func visit(_: InterfaceDeclWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Declaration with reference")
    }

    public open override func visit(_: InterfaceReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Reference")
    }
}
