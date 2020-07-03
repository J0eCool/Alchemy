// UTILS ------------------------

def contains(str, c):
    for(str) k:
        if k == c:
            return true
    return false

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
            let start = i
            var len = 1
            while text[start+len] != '\'':
                len++
            len++ // do include closing '
            ret.push(text.substring(i, len))
            i += len
        else:
            // identifiers
            let start = i
            var len = 1
            while not text[start+len].is_breaking:
                len++
            ret.push(text.substring(i, len))
            i += len
    return ret

// DRIVER -----------------------

let infile = "sample.alch"

let contents = assert(read_file(infile))
let tokens = lex(contents)
