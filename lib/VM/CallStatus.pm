# lib/VM/CallStatus.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::CallStatus {    #enum
    use MooseX::ClassAttribute;
    class_has 'CIST_NONE' => (
        is      => 'ro',
        isa     => 'Num',
        default => 0,
    );

    my $count = 0;
    for (
        qw/
        CIST_LUA
        CIST_HOOKED
        CIST_REENTRY
        CIST_YIELDED
        CIST_YPCALL
        CIST_STAT
        CIST_TAIL/
      )
    {
        class_has $_ => (
            is      => 'ro',
            isa     => 'Num',
            default => 1 << $count++,
        );
    }
}
1;
