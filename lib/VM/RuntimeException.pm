# lib/VM/RuntimeException.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::RuntimeException {
    has 'err_code' => (
        is  => 'rw',
        isa => 'Int',    #ThreadStatus
    );
}

1;
