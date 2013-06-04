# lib/VM/Object/Closure.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::Closure;
use lib '../../';
use plua;

BEGIN {
    my $class = __PACKAGE__;
    attr( $class, undef, 
        'closure_type' #Int
    );
}

sub get_upvalue { }
sub set_upvalue { }

1;
