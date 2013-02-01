# lib/VM/Object/LocalVar.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::LocalVar {    #no base class
    has 'var_name' => (
        is  => 'rw',
        isa => 'Str',
    );
    has [ 'start_pc', 'end_pc' ] => (
        is  => 'rw',
        isa => 'Int',
    );
}

1;
