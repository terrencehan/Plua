# lib/VM/Object/Closure.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

role VM::Object::Closure {
    use lib '../../';

    requires qw/get_upvalue set_upvalue/;

    has 'closure_type' => (
        is  => 'rw',
        isa => 'VM::Common::ClosureType',
    );

    method get_upvalue ( Num $n, ScalarRef [VM::Object] $val ) { }
    method set_upvalue ( Num $n, ScalarRef [VM::Object] $val ) { }
}

1;
