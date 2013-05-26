# lib/VM/Common/ClosureType.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::ClosureType { #enum
    use MooseX::ClassAttribute;
    my $count = 0;
    for (qw/LUA PERL/) {
        class_has $_ => (
            is      => 'ro',
            isa     => 'Num',
            default => $count++,
        );
    }
}
1;
