perl-lisp
=========

A lisp variant implemented by perl.

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
    sub hello { my ($name1, $name2) = @_;print("hello ", name1, " and ", name2, "\n"); print("hello ", name2, " or  ", name1, "\n")};
    hello("aaa", "bbb");



