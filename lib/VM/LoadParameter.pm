# lib/VM/LoadParameter.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::LoadParameter {
    #-BUILD (load_info => VM::LoadInfo, name => Str, mode => Str)
    has 'load_info' => (
        is       => 'rw',
        isa      => 'VM::LoadInfo',
        required => 1,
    );

    has [ 'name', 'mode' ] => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );
}

1;
