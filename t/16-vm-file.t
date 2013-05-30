# t/15-vm-file.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use VM::Common::LuaConf;
use Helper::BitConverter;
use_ok 'VM::File';

my $load_info = VM::File->open_file("t_files/luac.out");
isa_ok $load_info, 'VM::LoadInfo';

my @b = $load_info->peek_byte(4);

is( pack( "C*", @b ), VM::Common::LuaConf->LUA_SIGNATURE );

done_testing;
