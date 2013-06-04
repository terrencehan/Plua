# lib/VM/OpCode/OpMode.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::OpCode::OpMode;

BEGIN {
    my @modes = (
        'iABC',
        'iABx',
        'iAsBx',

        #iAx,
    );

    my $count = 0;
    for (@modes) {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $n = $count++;
        *t = sub {
            return $n;
        };
    }
}
1;
