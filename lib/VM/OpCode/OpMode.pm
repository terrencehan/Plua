# lib/VM/OpCode/OpMode.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::OpCode::OpMode {    #enum
    use MooseX::ClassAttribute;
    my @modes = (
        'iABC',
        'iABx',
        'iAsBx',

        #iAx,
    );

    my $count = 0;
    for (@modes) {
        class_has $_ => (
            is      => 'ro',
            isa     => 'Num',
            default => $count++,
        );
    }
}

1;
