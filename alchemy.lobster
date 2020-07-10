// UTILS ------------------------

def contains(str, c):
    for(str) k:
        if k == c:
            return true
    return false

def drop(list, n):
    let to_drop = max(list.length - n, 0)
    return list.slice(n, to_drop)

def map(list, f):
    let ret = []
    for(list) x:
        ret.push(f(x))
    return ret

// AST -------------------------

// forward declarations
class Declaration
class Expression

class Program:
    decls: [Declaration]
    exprs: [Expression]

class Declaration:
    name: string
    expr: Expression

class Function: Expression
    decls: [Declaration]
    expr: Expression
class StringLiteral: Expression
    val: string
class Identifier: Expression
    name: string
class Call: Expression
    callee: Expression
    args: [Expression]

// PARSER ----------------------

def lex(text):
    // Character classes
    def is_whitespace(c):
        return " \t\n\r".contains(c)
    def is_singular(c):
        return ";:,$#()[]{}".contains(c)
    def is_breaking(c):
        return c.is_whitespace or c.is_singular

    let ret = []
    var i = 0
    while i < text.length:
        let head = text[i]
        if head == '/' and text[i+1] == '/':
            // comments
            i += 2
            while text[i] != '\n':
                i++
        else: if head.is_whitespace():
            // ignore whitespace
            i++
        else: if head == '\'':
            // strings
            var len = 1
            while text[i+len] != '\'':
                len++
            len++ // do include closing '
            ret.push(text.substring(i, len))
            i += len
        else: if head.is_singular:
            ret.push(text.substring(i, 1))
            i++
        else:
            // identifiers
            var len = 1
            while not text[i+len].is_breaking:
                len++
            ret.push(text.substring(i, len))
            i += len
    return ret

// First step is to divide token stream on ';'s
def collect_statements(tokens):
    let ret = []
    var i = 0
    while i < tokens.length:
        var len = 0
        while i+len < tokens.length and tokens[i+len] != ";":
            len++
        ret.push(tokens.slice(i, len))
        i += len+1 //+1 to skip the ;
    return ret

def parse_expr(tokens) -> Expression?:
    assert(tokens.length > 0)
    let head = tokens[0]
    if tokens.length == 1:
        if head[0] == '\'':
            return StringLiteral { head.substring(1, head.length - 2) }
        else:
            return Identifier { head }
    else:
        if head == "fn":
            let expr = parse_expr(tokens.drop(1))
            if expr:
                return Function { [], expr }
            else:
                return nil
        // function call
        let parts = []
        var i = 0
        def try_push(ex):
            if ex:
                parts.push(ex)
            else:
                return nil from parse_expr
        while i < tokens.length:
            if tokens[i] == "(":
                i++
                var len = 0
                while tokens[i+len] != ")":
                    len++
                let expr = parse_expr(tokens.slice(i, len))
                if expr:
                    parts.push(expr)
                    i += len+1
                else:
                    return nil
            else: if tokens[i] == "$":
                parts.push(Call { Identifier { tokens[i+1] }, []})
                i += 2
            else:
                let expr = parse_expr(tokens.slice(i, 1))
                if expr:
                    parts.push(expr)
                    i++
                else:
                    return nil
        return Call { parts[0], parts.drop(1) }
    return nil

def parse(tokens):
    let ret = Program {
        decls: [],
        exprs: [],
    }

    let statements = collect_statements(tokens)
    for(statements) st:
        if st.length >= 2 and st[1] == "=":
            let expr = parse_expr(st.drop(2))
            if expr:
                ret.decls.push(Declaration {
                    name: st[0],
                    expr: expr,
                })
        else:
            let expr = parse_expr(st)
            if expr:
                ret.exprs.push(expr)
        // All unmatched patterns are discarded
    return ret

// INTERPRETER ------------------

// can be executed to produce a value
def unsupported(name, this, ret):
    print "UNSUPPORTED " + name + ": " + this
    assert(false)
    return ret
class IVal:
    def to_str():
        return unsupported("to_str", this, "")
    def getSymName():
        return unsupported("getSymName", this, "")

    // simplifies current value
    // - look up current identifier value
    // - execute a Call node
    def eval():
        return unsupported("eval", this, IVal{})
    // call current value with arguments
    // - look up method on value and call that
    // - execute a Func node
    def call(args):
        return unsupported("call", this, IVal{})


class ISym:
    name: string
    val: IVal
class IProg:
    symbols: [ISym]
    vals: [IVal]

class IUnit: IVal
    def eval():
        return IUnit{}

class INum: IVal
    val: float
    def eval():
        return INum{val}
class IStr: IVal
    val: string
    def eval():
        return IStr{val}
    def to_str():
        return val
    def call(args):
        assert(args.length >= 1)
        let next = args[0]
        let name = next.getSymName()

        // hardcoded for now
        assert name == "+"
        assert args.length == 2
        let other = args[1].eval()
        return IStr{val + other.to_str()}
class IFunc: IVal
    val: IVal
    def eval():
        return IFunc{val}
    def call(args):
        return val
class IIdent: IVal
    sym: ISym
    def eval():
        return sym.val.eval()
    def getSymName():
        return sym.name
class ICall: IVal
    callee: IVal
    args: [IVal]
    // Note: don't eval args, 
    def eval():
        let base = callee.eval()
        let ret = base.call(args)
        return ret.eval()

def fn_val_ty(args: [IVal]) -> IVal
class IBuiltin: IVal
    func: fn_val_ty
    def eval():
        return IBuiltin{func}
    def call(args):
        let vals = map(args) x: eval(x)
        let f = func
        return f(vals)

def lookup(prog, name):
    for(prog.symbols) sym:
        if sym.name == name:
            return sym
    return ISym { name, IUnit{} }

def validate(expr: Function, prog) -> IVal?:
    let valid = expr.expr.validate(prog)
    if valid:
        return IFunc { valid }
    return nil
def validate(expr: StringLiteral, prog) -> IVal?:
    return IStr { expr.val }
def validate(expr: Identifier, prog) -> IVal?:
    let sym = prog.lookup(expr.name)
    if sym:
        return IIdent { sym }
    return nil
def validate(expr: Call, prog) -> IVal?:
    let callee = expr.callee.validate(prog)
    if callee:
        let args = []
        for(expr.args) arg:
            let valid = arg.validate(prog)
            if valid:
                args.push(valid)
            else:
                return nil
        return ICall { callee, args }
    return nil

def interpreter_builtins():
    let builtins = []
    def builtin(name, func):
        builtins.push(ISym { name, IBuiltin { func } })

    builtin("print") args:
        let val = args[0]
        print val.to_str()
        IUnit{}

    return builtins

def validate(base_prog):
    let prog = IProg { interpreter_builtins(), [] }
    for(base_prog.decls) decl:
        let valid = decl.expr.validate(prog)
        if valid:
            prog.symbols.push(ISym { decl.name, valid })

    for(base_prog.exprs) expr:
        let val = expr.validate(prog)
        if val:
            prog.vals.push(val)
    return prog

def run(prog):
    def discard(x):
        // Need to do something with these eval'd values
        // so Lobster doesn't think we're leaking them
        return
    for(prog.vals) val:
        discard(val.eval())

// DRIVER -----------------------

let infile = "sample.alch"

let contents = assert(read_file(infile))
let tokens = lex(contents)
let ast = parse(tokens)
print ast
let prog = validate(ast)
print prog
prog.run()
