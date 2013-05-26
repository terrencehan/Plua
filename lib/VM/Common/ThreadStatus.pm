# lib/VM/Common/ThreadStatus.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::ThreadStatus {
    use MooseX::ClassAttribute;

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
        class_has $_ => (
            is      => 'ro',
            isa     => 'Int',
            default => $count++,
        );
    }
}

1;
