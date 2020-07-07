// UTILS ------------------------

def contains(str, c):
    for(str) k:
        if k == c:
            return true
    return false

def drop(list, n):
    let to_drop = max(list.length - n, 0)
    return list.slice(n, to_drop)

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
class IExpr
// a runtime value
class IVal

class ISym:
    name: string
    expr: IExpr
class IProg:
    symbols: [ISym]
    exprs: [IExpr]

class IFunc: IExpr
    expr: IExpr
class ILit: IExpr
    val: IVal
class IIdent: IExpr
    sym: ISym
class ICall: IExpr
    callee: IExpr
    args: [IExpr]

def fn_val_ty(args: [IVal]) -> IVal
class IBuiltin: IExpr
    func: fn_val_ty


// useful for epxressions not meant to be executed; e.g. unresolved symbols
class IInvalid: IExpr

enum IValKind:
    v_unit
    v_num
    v_str
    v_fn
    v_fn_ex
class IVal:
    kind: IValKind
    num_val: float
    str_val: string
    fn_val: fn_val_ty
    fn_ex_val: IFunc?

def base_base_val(f):
    return IVal { v_unit, 0, "", f, nil }
def i_unit() -> IVal:
    return base_base_val() args:
        i_unit()

def i_num(num):
    let ret = i_unit()
    ret.kind = v_num
    ret.num_val = num
    return ret
def i_str(str):
    let ret = i_unit()
    ret.kind = v_str
    ret.str_val = str
    return ret
def i_fn(f):
    let ret = i_unit()
    ret.kind = v_fn
    ret.fn_val = f
    return ret
def i_fn_ex(expr):
    let ret = i_unit()
    ret.kind = v_fn_ex
    ret.fn_ex_val = expr
    return ret

def lookup(prog, name):
    for(prog.symbols) sym:
        if sym.name == name:
            return sym
    return ISym { name, IInvalid{} }

def validate(expr: Function, prog) -> IExpr?:
    let valid = expr.expr.validate(prog)
    if valid:
        return IFunc { valid }
    return nil
def validate(expr: StringLiteral, prog) -> IExpr?:
    return ILit { i_str(expr.val) }
def validate(expr: Identifier, prog) -> IExpr?:
    let sym = prog.lookup(expr.name)
    if sym:
        return IIdent { sym }
    return nil
def validate(expr: Call, prog) -> IExpr?:
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
        switch val.kind:
            case v_unit:
                print "()"
            case v_num:
                print val.num_val
            case v_str:
                print val.str_val
            case v_fn:
                print "<func>"
            case v_fn_ex:
                print "<func-Ex>"
        i_unit()

    return builtins

def validate(base_prog):
    let prog = IProg { interpreter_builtins(), [] }
    for(base_prog.decls) decl:
        let valid = decl.expr.validate(prog)
        if valid:
            prog.symbols.push(ISym { decl.name, valid })

    for(base_prog.exprs) expr:
        let valid = expr.validate(prog)
        if valid:
            prog.exprs.push(valid)
    return prog

def eval(expr: IExpr):
    print "UNSUPPORTED EVAL: " + expr
    assert(false)
    return i_unit()

def getSymName(expr: IExpr):
    print "UNSUPPORTED SYM NAME: " + expr
    assert(false)
    return ""
def getSymName(expr: IIdent):
    return expr.sym.name

def call(val, args):
    if val.kind == v_fn:
        let vals = []
        for(args) arg:
            vals.push(arg.eval())
        let f = val.fn_val
        return f(vals)
    else: if val.kind == v_fn_ex:
        let ex = val.fn_ex_val
        assert(ex)
        return ex.expr.eval()
    else:
        assert(args.length >= 1)
        let next = args[0]
        let name = next.getSymName()

        // hardcoded for now
        assert name == "+"
        assert args.length == 2
        assert val.kind == v_str
        let other = args[1].eval()
        assert other.kind == v_str
        return i_str(val.str_val + other.str_val)

def eval(expr: ICall):
    let val = expr.callee.eval()
    return val.call(expr.args)
def eval(expr: ILit):
    return expr.val
def eval(expr: IIdent):
    return expr.sym.expr.eval()
def eval(expr: IBuiltin):
    return i_fn(expr.func)
def eval(expr: IFunc):
    return i_fn_ex(expr)

def run(prog):
    def discard(x):
        return
    for(prog.exprs) expr:
        // Need to do something with these eval'd values
        // so Lobster doesn't think we're leaking them
        discard(expr.eval())

// DRIVER -----------------------

let infile = "sample.alch"

let contents = assert(read_file(infile))
let tokens = lex(contents)
let ast = parse(tokens)
print ast
let prog = validate(ast)
print prog
prog.run()
