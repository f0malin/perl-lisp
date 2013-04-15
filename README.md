perl-lisp
=========

A lisp to perl compiler. It is insprired by the livescript project(http://livescript.net). 

Run:

    perl perl-lisp.pl test.plp

Code sample:

    (use LWP::Simple "get" "getstore")
    
    (print (get "http://www.sina.com.cn") "\n")
    
    (print (* 5 (+ 1 2)) "\n")
    (print "hello world" "\n")
    
    (sub hello '(name1 name2) '(
                                (print "hello " name1 " and " name2 "\n")
                                (print "hello " name2 " or  " name1 "\n")                   
                               ))
    
    (hello "aaa" "bbb")


Above code will produce:

    use LWP::Simple "get","getstore";
    print(get("http://www.sina.com.cn"), "\n");
    print((5*(1+2)), "\n");
    print("hello world", "\n");
    sub hello { my ($name1, $name2) = @_;print("hello ", $name1, " and ", $name2, "\n"); print("hello ", $name2, " or  ", $name1, "\n")};
    hello("aaa", "bbb");

Code sample 2:

    (use Data::Dumper "Dumper")
    
    (my x (dict
           "name" "Achilles"
           "age" 99
           boards (list
                   "sama"
                   "diantian"
                   )))
    
    (print (Dumper x) "\n")
    
    (print ({} x "age") "\n")

will procude: 

    use Data::Dumper "Dumper";
    my $x = {"name","Achilles","age",99,boards,["sama","diantian"]};
    print(Dumper($x), "\n");
    print($x->{"age"}, "\n");

A async PSGI sample: 

    (use AnyEvent)
    
    (closure '(env) '(
                      (return (closure '(res) '(
                                                (my w)
                                                (= w (-> AnyEvent timer "after" 3 "cb" (closure '() '(
                                                                                                  (call res
                                                                                                     (list
                                                                                                      200
                                                                                                      (list "content-type" "text/plain")
                                                                                                      (list "hello world\n")
                                                                                                      ))
                                                                                                  (undef w)
                                                                                                  )))))))))

Enjoy it!
