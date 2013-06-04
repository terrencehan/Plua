# lib/VM/Common/LuaConf.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Common::LuaConf;

BEGIN {
    my %h;

    $h{LUAI_BITSINT} = 32;
    $h{LUAI_MAXSTACK} = $h{LUAI_BITSINT} >= 32 ? 1000000 : 15000;
    $h{LUAI_FIRSTPSEUDOIDX} = -$h{LUAI_MAXSTACK} - 1000;           #for registry
    $h{LUA_SIGNATURE}       = pack "C*", 0x1b, 0x4c, 0x75, 0x61;   #"\u001bLua";
    $h{LUA_DIRSEP}          = '/';                                 #TODO
    $h{MAXTAGLOOP}          = 100;

    for ( keys %h ) {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $res = $h{$_};
        *t = sub {
            $res;
        };
    }
}

1;
