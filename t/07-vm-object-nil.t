# t/07-vm-object-nil.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More tests => 5;
use aliased 'VM::Common::LuaType';
BEGIN { use_ok('VM::Object::Nil') }

my $nil = VM::Object::Nil->new;

isa_ok $nil, 'VM::Object::Nil';

is $nil->is_nil, 1;
is $nil->is_false, 1;
is $nil->type, LuaType->LUA_TNIL;
