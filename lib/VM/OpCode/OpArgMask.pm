# lib/VM/OpCode/OpArgMask.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::OpCode::OpArgMask {    #enum
    use MooseX::ClassAttribute;
    my @masks = (
        'OpArgN',                # argument is not used
        'OpArgU',                # argument is used
        'OpArgR',                # argument is a register or a jump offset
        'OpArgK'                 # argument is a constant or register/constant
    );

    my $count = 0;
    for (@masks) {
        class_has $_ => (
            is      => 'ro',
            isa     => 'Num',
            default => $count++,
        );
    }
}

1;
