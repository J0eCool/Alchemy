# use Grammar::Tracer;

grammar Alchemy {
    rule TOP { ^ <stmt>* $ }

    rule stmt {
        | <call>
    }
    rule call {
        <ident> <expr> ';'
    }

    rule expr {
        | <string>
        | <ident>
    }
    token string {
        # capture contents between two quotes
        \' (<-[']>*) \'
    }
    token ident {
        <[\S] - [;]>+
    }
}

my %vm;
class AlchemyInterpret {
    method call($/) {
        if $<ident> eq 'print' {
            print $<expr>.made
        }
    }

    method expr($/) {
        make $<string>.made
    }
    method string($/) {
        make $/[0]
    }
}

my $data = slurp "sample.alch";
my $ast = Alchemy.parse($data, :actions(AlchemyInterpret));
# say $ast;
