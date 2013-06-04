# lib/VM/Common/ThreadStatus.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Common::ThreadStatus;

BEGIN {
    my $count = -1;
    for (
        qw/
        LUA_RESUME_ERROR
        LUA_OK
        LUA_YIELD
        LUA_ERRRUN
        LUA_ERRSYNTAX
        LUA_ERRMEM
        LUA_ERRGCMM
        LUA_ERRERR

        LUA_ERRFILE
        /
      )
    {
        *t = eval { "*" . __PACKAGE__ . "::" . $_ };
        my $n = $count++;
        *t = sub {
            return $n;
        };
    }
}

1;
