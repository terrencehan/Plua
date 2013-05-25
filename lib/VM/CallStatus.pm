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
        'CIST_LUA',       #call is running a Lua function
        'CIST_HOOKED',    #call is running a debug hook
        'CIST_REENTRY',   #call is running on same invocation of luaV_execute of previous call
        'CIST_YIELDED',   #call reentered after suspension
        'CIST_YPCALL',    #call is a yieldable protected call
        'CIST_STAT',      #call has an error status (pcall)
        'CIST_TAIL',      #call was tail called
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
