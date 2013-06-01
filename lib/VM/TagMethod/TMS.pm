# lib/VM/TagMethod/TMS.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::TagMethod::TMS {
    use MooseX::ClassAttribute;

    my $count = 0;
    for (
        qw/
        TM_INDEX
        TM_NEWINDEX
        TM_GC
        TM_MODE
        TM_LEN
        TM_EQ
        TM_ADD
        TM_SUB
        TM_MUL
        TM_DIV
        TM_MOD
        TM_POW
        TM_UNM
        TM_LT
        TM_LE
        TM_CONCAT
        TM_CALL
        TM_N
        /    # `TM_N' number of elements in the enum
      )
    {
        class_has $_ => (
            is      => 'ro',
            isa     => 'Int',
            default => $count++,
        );
    }
}

1;
