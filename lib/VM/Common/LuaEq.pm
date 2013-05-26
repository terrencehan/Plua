# lib/VM/Common/LuaEq.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::LuaEq {
    use MooseX::ClassAttribute;

    my $count = 0;
    for (
        qw/
		LUA_OPEQ	
		LUA_OPLT	
		LUA_OPLE	
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
