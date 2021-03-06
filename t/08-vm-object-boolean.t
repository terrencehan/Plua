# t/08-vm-object-boolean.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use aliased 'VM::Common::LuaType';
BEGIN { use_ok('VM::Object::Boolean') }

my $bool = VM::Object::Boolean->new( value => 1 );

isa_ok $bool, 'VM::Object::Boolean';

is $bool->is_false, 0;
is $bool->type,     LuaType->LUA_TBOOLEAN;

$bool->value(0);
is $bool->is_false, 1;

done_testing;
