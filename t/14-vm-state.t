# t/14-vm-state.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;
use aliased 'VM::Util';
use aliased 'VM::Common::LuaType';
use aliased 'VM::Common::LuaOp';
use aliased 'VM::Common::LuaDef';
use aliased 'VM::Common::ThreadStatus';

use_ok 'VM::State';

my $state = new VM::State;

is $state->o_arith( LuaOp->LUA_OPADD, 23, 1.2 ), 24.2;
is $state->o_arith( LuaOp->LUA_OPSUB, 23, 1.2 ), 21.8;
is $state->o_arith( LuaOp->LUA_OPMUL, 23, 1.2 ), 27.6;
is $state->o_arith( LuaOp->LUA_OPDIV, 23, 2 ),   11.5;
is $state->o_arith( LuaOp->LUA_OPMOD, 23, 2 ),   1;
is $state->o_arith( LuaOp->LUA_OPPOW, 3,  2 ),   9;
is $state->o_arith( LuaOp->LUA_OPUNM, 3,  3 ),   -3;

my $result = 0;
is( ( $state->o_str2decimal( "123",         \$result ), $result ), 123 );
is( ( $state->o_str2decimal( "123.123",     \$result ), $result ), 123.123 );
is( ( $state->o_str2decimal( "  123.123",   \$result ), $result ), 123.123 );
is( ( $state->o_str2decimal( "-123",        \$result ), $result ), -123 );
is( ( $state->o_str2decimal( "  123.123e2", \$result ), $result ), 12312.3 );
is( ( $state->o_str2decimal( "123.123e-2",  \$result ), $result ), 1.23123 );
is( ( $state->o_str2decimal( "0x11",        \$result ), $result ), 17 );
is( ( $state->o_str2decimal( "-0x11",       \$result ), $result ), -17 );
is( ( $state->o_str2decimal( "0x11.1",      \$result ), $result ), 17.0625 );
is( ( $state->o_str2decimal( "-0x11.1",     \$result ), $result ), -17.0625 );
is( ( $state->o_str2decimal( "-0xaP1",      \$result ), $result ), -20 );

is $state->api,                $state;
is $state->type,               LuaType->LUA_TTHREAD;
is $state->status,             ThreadStatus->LUA_OK;
is $state->is_thread,          1;
is $state->num_none_yieldable, 1;
is $state->num_perl_calls,     0;
is $state->hook_mask,          0;
is $state->err_func,           0;
is $state->base_hook_count,    0;
isa_ok $state->g,              'VM::GlobalState';

my %lua_file = (
    't_files/5.2/num.bin'         => undef,
    't_files/5.2/num2.bin'        => undef,
    't_files/5.2/if.bin'          => 'yes1yes2no3no4yes5',
    't_files/5.2/table.bin'       => '[LuaNumber(7)][LuaNumber(1)]',
    't_files/5.2/hello_world.bin' => 'hello world',
    't_files/5.2/hello_fun.bin'   => 'hello',
    't_files/5.2/100_num_sum.bin' => '[LuaNumber(5050)]',
);

close STDOUT;
for my $file_path ( keys %lua_file ) {
    my $output = '';
    open STDOUT, ">", \$output;
    my $state1 = new VM::State;
    $state1->l_open_libs();
    my $status = $state1->l_do_file($file_path);
    is $status, ThreadStatus->LUA_OK, $file_path;

    if ( $lua_file{$file_path} ) {
        is $output, $lua_file{$file_path}, 'output';
    }
}

done_testing;
