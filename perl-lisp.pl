use strict;
use warnings;

use Smart::Comments '###';
use Data::Dumper qw(Dumper);

my $file = $ARGV[0];

translate($file);

exit;

use constant VOID => 0;
use constant SYMBOL => 1;
use constant QUOTE => 2;

use constant OPERATORS => qw(+ - * /);

sub translate {
    my $infile = shift;
    my $outfile = $infile;
    $outfile =~ s/\..*?$/.pl/;
    ### $outfile

    open my $fh, $infile or die $!;
    my $content;
    {
        local $/;
        $content = <$fh>;
    }
    close $fh;

    my @result;
    my @stack;
    my @symbols;
    my $symbol = "";
    my $statement = "";

    my ($c, $s); # char, state
    $s = VOID;
    for (0 .. length($content)) {
        $c = substr($content, $_, 1);

        my $ns;
        my $op;
        
        #### before: $c,$s
        if ($c =~ /\s/) {
            $ns = [0, 0, 2];

            $op = [0,
                   sub {
                       push @symbols, $symbol;
                       $symbol = "";
                   },
                   sub {
                       $symbol .= $c;
                   }];
        } elsif ($c eq '(') {
            $ns = [0, -1, 2];
            $op = [sub {
                       #return unless @symbols;
                       my @symbols2 = @symbols;
                       push @stack, \@symbols2;
                       @symbols = ();
                   },
                   0,
                   sub {
                       $symbol .= $c;
                   }];
        } elsif ($c eq ')') {
            $ns = [0, 0, 2];
            $op = [sub {
                       my $last = pop @stack;
                       push @{$last}, make_statement(@symbols);
                       @symbols = @{$last};
                       if (scalar(@stack) == 0) {
                           push @result, shift(@symbols);
                       }
                   },
                   sub {
                       push @symbols, $symbol;
                       $symbol = "";
                       my $last = pop @stack;
                       push @{$last}, make_statement(@symbols);
                       @symbols = @{$last};
                       if (scalar(@stack)==0) {
                           push @result, shift(@symbols);
                           @symbols = ();
                       }
                   },
                   sub {
                       $symbol .= $c;
                   }];
        } elsif ($c eq '"') {
            $ns = [2, -1, 0];
            $op = [sub {
                       $symbol .= $c;
                   },
                   0,
                   sub {
                       $symbol .= $c;
                       push @symbols, $symbol;
                       $symbol = "";
                   }];
        } else { # symbol
            $ns = [1, 1, 2];
            $op = [sub {
                       $symbol .= $c;
                   },
                   sub {
                       $symbol .= $c;
                   },
                   sub {
                       $symbol .= $c;
                   }];
        }

        my $s2 = $ns->[$s];
        if ($s2 == -1) {
            die "invalid symbol";
        }

        my $sub = $op->[$s];
        if (ref($sub) eq 'CODE') {
            $sub->();
        }

        $s = $s2;
        #### after: $c,\@stack, \@symbols
        #print $c, Dumper(\@stack), "\n";
    }
    open my $fh2, ">$outfile" or die $!;
    print $fh2 $_ . ";\n" for @result;
    close $fh2;
}

sub make_statement {
    my $op = shift;
    if (scalar(@_) == 2 and grep {$op eq $_} OPERATORS) {
        return "(" . $_[0] . $op . $_[1] . ")";
    } else {
        return $op . "(" . join(",", @_) . ")";
    }
}
