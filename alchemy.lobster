// UTILS ------------------------

def contains(str, c):
    for(str) k:
        if k == c:
            return true
    return false

// AST -------------------------

class Declaration
class Program:
    statements: [Declaration]

class Expression
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

// PARSER ----------------------

def lex(text):
    // Character classes
    def is_whitespace(c):
        return " \t\n\r".contains(c)
    def is_breaking(c):
        return c.is_whitespace or c == ';'

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
        else:
            // identifiers
            var len = 1
            while not text[i+len].is_breaking:
                len++
            ret.push(text.substring(i, len))
            i += len
    return ret

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

def parse(tokens):
    let ret = Program {
        statements: [],
    }

    def parse_expr(expr_tokens):
        return UnknownExpression { expr_tokens }

    let statements = collect_statements(tokens)
    for(statements) st:
        if st.length >= 2 and st[1] == "=":
            let expr = parse_expr(st.slice(2, st.length - 2))
            if expr:
                ret.statements.push(Declaration {
                    name: st[0],
                    expr: expr,
                })
        // All unmatched patterns are considered as 
    return ret

// DRIVER -----------------------

let infile = "sample.alch"

let contents = assert(read_file(infile))
let tokens = lex(contents)
let ast = parse(tokens)
print ast
