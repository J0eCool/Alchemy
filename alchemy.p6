# use Grammar::Tracer;

grammar Alchemy {
    token TOP { ^ <stmt>* $ }
    rule stmt { <comment> | <assign> ';' | <call> ';' }
    token comment { "//" .*? "\n" }
    rule assign { <identifier> '=' <call> }

    rule call { (<expr> \s*)+ }
    token expr { <single_call> | <func> | <literal> | <identifier> }
    token identifier { <[\S] - [;]>+ }
    token single_call { '$' <identifier> }
    token literal { <lit_str> | <lit_num> }
    token lit_str { "'" <-[']>* "'" }
    token lit_num { \d+ }
    token func { 'fn' \s+ <call> }
}

my $data = slurp "sample.alch";
my $ast = Alchemy.parse($data);
say $ast;
