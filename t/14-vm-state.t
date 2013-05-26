# t/11-vm-callstatus.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;
use aliased 'VM::Common::LuaOp';

use_ok 'VM::State';

my $state = new VM::State;

is VM::State->o_arith( LuaOp->LUA_OPADD, 23, 1.2 ), 24.2;
is VM::State->o_arith( LuaOp->LUA_OPSUB, 23, 1.2 ), 21.8;
is VM::State->o_arith( LuaOp->LUA_OPMUL, 23, 1.2 ), 27.6;
is VM::State->o_arith( LuaOp->LUA_OPDIV, 23, 2 ),   11.5;
is VM::State->o_arith( LuaOp->LUA_OPMOD, 23, 2 ),   1;
is VM::State->o_arith( LuaOp->LUA_OPPOW, 3,  2 ),   9;
is VM::State->o_arith( LuaOp->LUA_OPUNM, 3,  3 ),   -3;

my $result = 0;
is( ( VM::State->o_str2decimal( "123",         \$result ), $result ), 123 );
is( ( VM::State->o_str2decimal( "123.123",     \$result ), $result ), 123.123 );
is( ( VM::State->o_str2decimal( "  123.123",   \$result ), $result ), 123.123 );
is( ( VM::State->o_str2decimal( "-123",        \$result ), $result ), -123 );
is( ( VM::State->o_str2decimal( "  123.123e2", \$result ), $result ), 12312.3 );
is( ( VM::State->o_str2decimal( "123.123e-2",  \$result ), $result ), 1.23123 );
is( ( VM::State->o_str2decimal( "0x11",        \$result ), $result ), 17 );
is( ( VM::State->o_str2decimal( "-0x11",       \$result ), $result ), -17 );
is( ( VM::State->o_str2decimal( "0x11.1",      \$result ), $result ), 17.0625 );
is( ( VM::State->o_str2decimal( "-0x11.1", \$result ), $result ), -17.0625 );
is( ( VM::State->o_str2decimal( "-0xaP1",   \$result ), $result ), -20 );

done_testing;
