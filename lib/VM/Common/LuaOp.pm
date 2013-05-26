# lib/VM/Common/LuaOp.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::LuaOp {
    use MooseX::ClassAttribute;

    my $count = 0;
    for (
        qw/
		LUA_OPADD	
		LUA_OPSUB	
		LUA_OPMUL	
		LUA_OPDIV	
		LUA_OPMOD	
		LUA_OPPOW	
		LUA_OPUNM	
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
