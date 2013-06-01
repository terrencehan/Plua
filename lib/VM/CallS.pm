# lib/VM/CallS.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::CallS {

    #-BUILD (func => VM::StkId, num_results => Int)
    has 'func' => (
        is  => 'rw',
        isa => 'VM::StkId',
    );

    has 'num_results' => (
        is  => 'rw',
        isa => 'Int',
    );
}

1;
