# lib/VM/OpCode/OpArgMask.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::OpCode::OpArgMask;

BEGIN {

    my @masks = (
        'OpArgN',    # argument is not used
        'OpArgU',    # argument is used
        'OpArgR',    # argument is a register or a jump offset
        'OpArgK'     # argument is a constant or register/constant
    );

    my $count = 0;
    for (@masks) {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $n = $count++;
        *t = sub {
            return $n;
        };
    }

}
1;
