# lib/VM/Common/ClosureType.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

package VM::Common::ClosureType;

BEGIN {
    my $count = 0;
    for (qw/LUA PERL/) {
        no warnings;
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $n = $count++;
        *t = sub {
            return $n;
        };

    }
}

1;
