use strict;
use warnings;

use Smart::Comments '###';
use Data::Dumper qw(Dumper);
use Carp qw(croak);

my $file = $ARGV[0];

translate($file);

exit;

our $high_order = {};

use constant VOID => 0;
use constant SYMBOL => 1;
use constant QUOTE => 2;
use constant SQ => 3;

use constant OPERATORS => qw(+ - * /);

sub translate {
    my $infile = shift;
    my $outfile = $infile;
    $outfile =~ s/\..*?$/.pl/;
    ### $outfile

    open my $fh, $infile or die $!;
    open my $fh2, ">$outfile" or die $!;
    my $content = "";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^#/;
        $content .= $line;
    }
    my $ret = evaluate($content);
    ### $ret
    if ($ret) {
        print $fh2 $ret, ";\n";
    } else {
        print $fh2 $ret, "\n";
    }

    close $fh;
    close $fh2;
}
    
sub evaluate {
    my $content = shift;
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
            $ns = [0, 0, 2, -1];
            $op = [0,
                   sub {
                       push @symbols, $symbol;
                       $symbol = "";
                   },
                   sub {
                       $symbol .= $c;
                   },
                   0];
        } elsif ($c eq '(') {
            $ns = [0, -1, 2, 0];
            $op = [sub {
                       #return unless @symbols;
                       my @symbols2 = @symbols;
                       push @stack, \@symbols2;
                       @symbols = ();
                   },
                   0,
                   sub {
                       $symbol .= $c;
                   },
                   sub {
                       #return unless @symbols;
                       my @symbols2 = @symbols;
                       push @stack, \@symbols2;
                       @symbols = ("'");
                   }];
        } elsif ($c eq ')') {
            $ns = [0, 0, 2, -1];
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
                   },
                   0];
        } elsif ($c eq '"') {
            $ns = [2, -1, 0, -1];
            $op = [sub {
                       $symbol .= $c;
                   },
                   0,
                   sub {
                       $symbol .= $c;
                       push @symbols, $symbol;
                       $symbol = "";
                   },
                   0];
        } elsif ($c eq "'") {
            $ns = [3, 1, 2, -1];
            $op = [0,
                   sub {
                       $symbol .= $c
                   },
                   sub {
                       $symbol .= $c
                   },
                   0];
        } else { # symbol
            $ns = [1, 1, 2, -1];
            $op = [sub {
                       $symbol .= $c;
                   },
                   sub {
                       $symbol .= $c;
                   },
                   sub {
                       $symbol .= $c;
                   },
                   0];
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
        ### after: $c,$s,\@stack, \@symbols
        #print $c, Dumper(\@stack), "\n";
    }
    
    return join(";\n", @result);
}

use constant TYPE_LIST => 1;

sub make_statement {
    my $op = shift;
    if (grep {$op eq $_} OPERATORS) {
        check_args(2, \@_);
        return "(" . $_[0] . $op . $_[1] . ")";
    } elsif ($op eq 'use') {
        check_args(1, \@_);
        return $op . " " . shift . " " . join(",",@_);
    } elsif ($op eq 'list')  {
        check_args(1, \@_);
        return "[" . join(",", @_) . "]";
    } elsif ($op eq "'") {
        return \@_;
    } elsif ($op eq 'sub') {
        ### @_
        check_args(3, \@_, 0, TYPE_LIST, TYPE_LIST);
        my ($name, $args, $block) = @_;
        ### $block
        my $str;
        if (scalar(@$args) > 0) {
            $str =  "sub " . $name . " { my (" . join(", ", map {'$'.$_} @$args) . ') = @_;' . join("; " , @$block) . "}";
        } else {
            $str =  "sub " . $name . " { " . join("; " , @$block) . "}";
        }
        return $str;
    } elsif ($op eq '{}') {
        return $_[0]."->{".$_[1]."}";
    } elsif ($op eq '[]') {
        return $_[0]."->[".$_[1]."]";
    } elsif ($op eq 'my') {
        if (scalar(@_) == 1) {
            return 'my $' . $_[0];
        }
        return 'my $' . $_[0] . " = " . $_[1];
    } elsif ($op eq 'dict') {
        my $str = "{" . join(",", @_) . "}";
        return $str;
    } elsif ($op eq 'closure') {
        ### @_
        check_args(2, \@_, TYPE_LIST, TYPE_LIST);
        my ($args, $block) = @_;
        ### $block
        my $str;
        if (scalar(@$args) > 0) {
            $str =  "sub { my (" . join(", ", map {'$'.$_} @$args) . ') = @_;' . join("; " , @$block) . "}";
        } else {
            $str =  "sub { " . join("; " , @$block) . "}";
        }
        return $str;
    } elsif ($op eq 'call') {
        my ($func, @args) = @_;
        return '$' . $func . '->('. join(",", @args) . ')';
    } elsif ($op eq '=') {
        return '$' . $_[0] . "=" . $_[1];
    } elsif ($op eq '->') {
        my ($o, $method, @args) = @_;
        return $o . '->' . $method . '(' . join(",",@args) . ")";
    } else {    # normal function
        for (0 .. $#_) {
            if ($_[$_] !~ /[\( ]/ && $_[$_] =~ /^[^\-0-9"]/) {
                $_[$_] = '$' . $_[$_];
            }
        }
        return $op . "(" . join(", ", @_) . ")";
    }
}

sub check_args {
    my ($count, $args, @types) = @_; 
    if ($count >= 0 && scalar($args) < $count) {
        croak("invalid args count");
    }
    return unless @types;
    for (0 .. $#types) {
        if ($types[$_] == TYPE_LIST) {
            croak "invalid args: index " . $_ unless ref($args->[$_]) eq 'ARRAY';
        }
    }
}
