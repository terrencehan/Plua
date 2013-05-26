# lib/VM/Object/Upvalue.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::Upvalue extends VM::Object {
    use lib '../../';
    use VM::StkId;
    use VM::Object::Nil;
    use VM::Common::LuaType;

    #-BUILD ()

    has 'v' => (
        is  => 'rw',
        isa => 'VM::StkId',
    );

    has 'value' => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object]',
        default => sub { [] },
    );

    method BUILD {
        $self->type( VM::Common::LuaType->LUA_TUPVAL );
        push $self->value, VM::Object::Nil->new();
        $self->v( new VM::StkId( list => $self->value, index => 0 ) );
    }

}
1;
