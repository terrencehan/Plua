# lib/VM/Object/UserData.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::UserData extends VM::Object {
    use lib '../../';
    use VM::Common::LuaType;

    #-BUILD (value => Any)

    has 'value' => (
        is  => 'ro',
        isa => 'Any',
    );

    has 'length' => (
        is      => 'ro',
        isa     => 'Int',
        default => 0,
    );

    has 'meta_table' => (
        is      => 'rw',
        isa     => 'VM::Object::Table',
    );

    method BUILD {
        $self->type(VM::Common::LuaType->LUA_TUSERDATA);
    }
}

1;
