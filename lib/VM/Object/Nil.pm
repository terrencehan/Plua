# lib/VM/Object/Nil.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::Nil extends VM::Object {
    use VM::Type;

    method BUILD {
        $self->is_nil(1);
        $self->is_false(1);
        $self->type( VM::Type->LUA_TNIL );
    }
}

1;
