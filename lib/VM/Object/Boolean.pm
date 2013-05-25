# lib/VM/Object/Boolean.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::Boolean extends VM::Object {

    #--BUILD(value => bool)
    use lib '../../';
    use VM::Common::LuaType;

    has value => (
        is       => 'rw',
        isa      => 'Bool',
        required => 1,
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->is_false( not $new );
        },
    );


    method BUILD ($args) {
        $self->type( VM::Common::LuaType->LUA_TBOOLEAN );
    }
}

1;
