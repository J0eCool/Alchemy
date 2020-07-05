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

class UnknownExpression: Expression
    tokens: [string]
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
        if head.is_whitespace():
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
    else: if tokens.length > 1:
        if head == "fn":
            let expr = parse_expr(tokens.drop(1))
            if expr:
                return Function {
                    decls: [],
                    expr: expr,
                }
        else:
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
                    try_push(parse_expr(tokens.slice(i, len)))
                    i += len+1
                else: if tokens[i] == "$":
                    try_push(Call { Identifier { tokens[i+1] }, []})
                    i += 2
                else:
                    try_push(parse_expr(tokens.slice(i, 1)))
                    i++
            return Call { parts[0], parts.drop(1) }
        //     if head == "(":
        //     var i = 1
        //     while tokens[i] != ")":
        //         i++
        //     let 
        // else: if head == "print":
        //     let expr = parse_expr(tokens.drop(1))
        //     if expr:
        //         return PrintExpression { expr }
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

// DRIVER -----------------------

let infile = "sample.alch"

let contents = assert(read_file(infile))
let tokens = lex(contents)
let ast = parse(tokens)
print ast
