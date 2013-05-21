# lib/VM/Object/UpvalDesc.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::UpvalDesc {    # no base class
    has name     => ( is => 'rw', isa => 'Str', );
    has index    => ( is => 'rw', isa => 'Int', );
    has in_stack => ( is => 'rw', isa => 'Bool', );
}

1;
