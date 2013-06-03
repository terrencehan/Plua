# lib/VM/Common/LuaType.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::LuaType {
    use MooseX::ClassAttribute;

    my $count = -1;
    for (
        qw/
        LUA_TNONE
        LUA_TNIL
        LUA_TBOOLEAN
        LUA_TLIGHTUSERDATA
        LUA_TNUMBER
        LUA_TSTRING
        LUA_TTABLE
        LUA_TFUNCTION
        LUA_TUSERDATA
        LUA_TTHREAD

        LUA_TUINT64
        NUMTAGS

        LUA_TPROTO
        LUA_TUPVAL
        LUA_TDEADKEY
        /
      )
    {
        class_has $_ => (
            is      => 'ro',
            isa     => 'Int',
            default => $count++,
        );
    }
}

1;
