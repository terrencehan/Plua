# lib/VM/Common/LuaOp.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Common::LuaOp;

BEGIN {
    my $count = 0;
    for (
        qw/
        LUA_OPADD
        LUA_OPSUB
        LUA_OPMUL
        LUA_OPDIV
        LUA_OPMOD
        LUA_OPPOW
        LUA_OPUNM
        /
      )
    {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $n = $count++;
        *t = sub {
            return $n;
        };
    }
}

1;
