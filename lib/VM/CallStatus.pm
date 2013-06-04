# lib/VM/CallStatus.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::CallStatus;

BEGIN {
    my $count = 0;
    for (
        'CIST_LUA',       #call is running a Lua function
        'CIST_HOOKED',    #call is running a debug hook
        'CIST_REENTRY'
        ,   #call is running on same invocation of luaV_execute of previous call
        'CIST_YIELDED',    #call reentered after suspension
        'CIST_YPCALL',     #call is a yieldable protected call
        'CIST_STAT',       #call has an error status (pcall)
        'CIST_TAIL',       #call was tail called
      )
    {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $n = $count++;
        *t = sub {
            return 1 << $n;
        };

    }

    for ( 'CIST_NONE', ) {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        *t = sub {
            return 0;
        };

    }
}
1;
