# lib/VM/Common/LuaConstants.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::LuaConstants {
    use MooseX::ClassAttribute;

    my %h;

    $h{LUA_NOREF}  = -2;
    $h{LUA_REFNIL} = -1;

    for ( keys %h ) {
        class_has $_ => (
            is      => 'ro',
            default => $h{$_},
        );
    }
}

1;
