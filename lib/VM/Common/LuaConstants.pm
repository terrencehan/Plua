# lib/VM/Common/LuaConstants.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Common::LuaConstants;

BEGIN {
    my %h;

    $h{LUA_NOREF}  = -2;
    $h{LUA_REFNIL} = -1;

    for ( keys %h ) {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $res = $h{$_};
        *t = sub {
            $res;
        };
    }
}

1;
