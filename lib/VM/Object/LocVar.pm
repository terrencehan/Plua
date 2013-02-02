# lib/VM/Object/LocVar.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::LocVar {    #no base class
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
