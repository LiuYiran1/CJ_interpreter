# 实验报告

### 代码结构设计

#### 1. 静态作用域分析 (`src/executor/AccessLinkBuilder.cj`)
在 `src/executor` 中添加了 `AccessLinkBuilder` 类。
- **功能**：
  - 负责在解释器运行前对 AST 进行一遍静态扫描。
  - 构建每个 AST 节点（主要是 `Block` 和函数定义）的静态父级作用域（Access Link）模板。
  - 也为了实现对于**空块**的识别

#### 2. 修正 (`src/executor/ActivationRecords.cj`)
修正并扩展了 `ActivationRecords` 及其子类 `FuncActivationRecords` 和 `BlockActivationRecords`。
- **逻辑修正**：
  - 能区分 **Control Link (动态链)** 和 **Access Link (静态链)**。Control Link 指向调用者，用于函数返回；Access Link 指向定义时的环境，用于变量查找。
  - 在 `getStaticRecord` 和 `setStaticRecord` 中增加了 `isNonLocal` 标志位及递归传递逻辑，为了实现**内层函数不允许访问外层函数的可变非局部变量**的语义检查
- **参数绑定**：
  - 在 `FuncActivationRecords` 中实现了 `assignParams`，并在绑定形参时强制将其 `keyword` 设为 `LET`，确保形参在函数体内不可被重新赋值。

#### 3. 值的表示 (`src/executor/Value.cj`)
在 `Value` 枚举中加入了函数的运行时表示：
- `VFunction(FuncValue)`：
  - `FuncValue` 类中包含 `FuncDecl`（函数定义）和 `capturedEnv`（**捕获的闭包环境**）。这是实现闭包的核心，使得函数离开定义作用域后仍能访问当时的环境。
- `VMain(MainValue)`：用于特殊处理 `main` 函数。

#### 4. 解释器核心 (`src/executor/Evaluator.cj`)
大幅重构了 `Evaluator` 以支持复杂的语言特性：
- **两遍扫描机制 (`visit(Program)`)**：
  - **Pass 1**：注册所有全局函数（允许全局变量初始化时调用任何位置定义的函数）。
  - **Pass 2**：按顺序初始化全局变量（强制全局变量的定义顺序依赖，防止使用未定义的变量）。
- **作用域链式嵌套 (`Scope Chaining`)**：
  - 在 `visit(VarDecl)` 中，每定义一个变量都会创建一个新的嵌套 `BlockActivationRecords`，替代旧的栈顶记录。这完美解决了同个块内变量定义的顺序可见性问题（防止闭包捕获到“未来”定义的变量）。
- **函数调用逻辑完善 (`visit(CallExpr)`)**：
  - 实现了**词法作用域**（Lexical Scoping）：在调用者的环境中计算实参值，然后切换到被调用者的环境（恢复闭包捕获的 Access Link）。
  - 实现了**即时类型检查**：每计算一个实参立即检查其与形参的类型匹配情况。
  - 实现了**返回值类型检查**：函数执行结束后检查返回值与声明类型是否一致。

#### 5. 变量记录 (`src/executor/Record.cj`)
- 增强了 `updateValue` 逻辑：
  - 支持对未初始化变量的首次赋值。
  - 严格检查 `LET` 和 `FUNC` 类型的不可变性，禁止对函数名和 `let` 变量赋值。
  - 增加了对函数类型的兼容性检查。

### 支持的功能特性

#### 1. 函数类型的检查与判断
- 实现了 `areTypesEqual` 和 `checkFuncTypeMatch` / `checkValueTypeMatch` 辅助方法。
- 支持**高阶函数**的类型检查：不仅检查基础类型，还递归检查函数类型（参数个数、参数类型、返回值类型）的结构等价性。
- 在赋值表达式 `AssignExpr` 和函数调用 `CallExpr` 中均加入了严格的类型校验。

#### 2. 实现返回值逻辑
- 使用 `ReturnException` 机制来处理 `return` 语句，能够从深层嵌套的语句块中直接跳出并携带返回值，直到被 `visit(CallExpr)` 捕获。

#### 3. 内置函数保护
- 在全局定义时强制检查变量名和函数名，禁止重定义内置函数 `println`，否则抛出 `DUPLICATED_DEF`。

### 我认为的亮点

1.  **闭包的完整实现**：
    通过在 `Value.VFunction` 中携带 `capturedEnv`，并在函数调用时恢复 `Access Link`，完美实现了闭包特性。使得函数可以作为一等公民传递，且能正确访问定义时的上下文。

2.  **作用域链式设计 (Scope Chaining)**：
    在处理 `VarDecl` 时，不只是简单地向当前 Map 添加变量，而是创建新的作用域节点并压栈。这种设计巧妙地解决了**块级作用域中变量声明的顺序性问题**（即声明前的代码无法访问该变量，且闭包不会捕获到该变量声明之后的同名变量）。

3.  **严格的语义安全检查**：
    实现了非常细致的语义检查，包括：
    - 禁止修改 `let` 变量、函数名和形参（`ASSIGN_IMMUT_VAR`）。
    - 禁止内层函数修改外层函数的 `var` 变量（`FUNC_USE_MUTABLE_NONLOCAL`），同时正确排除了全局变量。
    - 全局变量初始化的顺序依赖检查。
    - 高阶函数的签名匹配检查。

### 遇到的问题和解决方案

1.  **问题：递归函数 (`fib`) 执行时变量被覆盖**
    - **现象**：计算斐波那契数列时，递归调用的内层函数修改了参数 `n`，导致外层函数的 `n` 也变了，计算结果错误。
    - **原因**：最初的实现中，解释器复用了 `AccessLinkBuilder` 生成的同一个 `ActivationRecords` 对象，导致所有递归层级共享同一个变量表。
    - **解决方案**：在运行时（`Evaluator`）进入函数或块时，基于静态分析的模板 **`new`** 一个新的 `ActivationRecords` 实例，确保每次调用都有独立的栈帧。1

2.  **问题：动态作用域导致的变量查找错误**
    - **现象**：函数内部能访问到调用者的局部变量。
    - **原因**：在 `visit(CallExpr)` 中，错误地将新栈帧的 `accessLink` 指向了 `curRecords`（调用者环境），或者在切换环境后才计算参数表达式。
    - **解决方案**：
        1. 严格遵守**词法作用域**规则：新栈帧的 `accessLink` 必须指向闭包捕获的 `capturedEnv`（或全局）。
        2. 调整执行顺序：先在当前环境（调用者）中计算所有实参的值，然后再切换 `curRecords` 到新函数环境进行参数绑定。

3.  **问题：闭包捕获了“未来”定义的变量**
    - **现象**：在一个块中，先定义函数 `f`，后定义变量 `x`。调用 `f` 时竟然能访问到 `x`。
    - **原因**：同一个块内的所有变量都存在同一个 `HashMap` 中，闭包捕获了这个 Map 的引用。
    - **解决方案**：修改 `visit(VarDecl)`，每定义一个变量就创建一个新的嵌套作用域（BlockRecord），利用链表结构隔离声明前后的环境。

4.  **问题：全局变量 `println` 重名检查失效**
    - **现象**：用户可以定义 `var println = 1`，导致后续无法调用内置函数。
    - **解决方案**：在 `visit(Program)` 的初始化循环中，显式添加了对标识符名称是否为 `"println"` 的检查，若重名则抛出 `DUPLICATED_DEF` 异常。