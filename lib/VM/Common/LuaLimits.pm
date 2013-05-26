# lib/VM/Common/LuaLimits.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::LuaLimits {
    use MooseX::ClassAttribute;

    my %h;

    $h{MAX_INT}        = 0b01111111_11111111_11111111_11111111 - 2;    #TODO
    $h{MAXUPVAL}       = 0b11111111;                                   #TODO
    $h{LUAI_MAXCCALLS} = 200;
    $h{MAXSTACK}       = 250;

    for ( keys %h ) {
        class_has $_ => (
            is      => 'ro',
            default => $h{$_},
        );
    }
}

1;
