# lib/VM/Common/LuaConf.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::LuaConf {
    use MooseX::ClassAttribute;

    my %h;

    $h{LUAI_BITSINT}        = 32;
    $h{LUAI_MAXSTACK}       = $h{LUAI_BITSINT} >= 32 ? 1000000 : 15000;
    $h{LUAI_FIRSTPSEUDOIDX} = -$h{LUAI_MAXSTACK} - 1000;
    $h{LUA_SIGNATURE}       = "\u001bLua";
    $h{LUA_DIRSEP}          = '/';                                        #TODO

    for ( keys %h ) {
        class_has $_ => (
            is      => 'ro',
            default => $h{$_},
        );
    }
}

1;
