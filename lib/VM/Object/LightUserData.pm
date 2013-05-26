# lib/VM/Object/LightUserData.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::LightUserData extends VM::Object {
    use lib '../../';
    use VM::Common::LuaType;

    #-BUILD (value => Any)

    has 'value' => (
        is  => 'ro',
        isa => 'Any',
    );

    method BUILD {
        $self->type(VM::Common::LuaType->LUA_TLIGHTUSERDATA);
    }
}
1;
