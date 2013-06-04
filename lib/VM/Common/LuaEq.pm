# lib/VM/Common/LuaEq.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Common::LuaEq;

BEGIN {
    my $count = 0;
    for (
        qw/
        LUA_OPEQ
        LUA_OPLT
        LUA_OPLE
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
