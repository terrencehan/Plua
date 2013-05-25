# t/06-vm-object-number.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More tests => 16;
use aliased 'VM::Common::LuaType';
BEGIN { use_ok('VM::Object::Number') }

my $num1 = VM::Object::Number->new( value => 2 );
my $num2 = VM::Object::Number->new( value => 3 );

isa_ok $num1, 'VM::Object::Number';

is $num1->to_num, 2;

is $num1->to_string,  "[LuaNumber(2)]";
is $num1->to_literal, "[LuaNumber(2)]";

is $num1 == $num2, '';
is $num1 == $num1, 1;
is $num1 == undef, 0;
is undef == $num1, 0;
is $num1 != $num2, 1;

is( ( $num1 + $num2 )->to_num, 5 );
is( ( $num1 * $num2 )->to_num, 6 );
is( ( $num1 - $num2 )->to_num, -1 );
is( ( $num1 / $num2 )->to_num, 2 / 3 );

is $num1->type,      LuaType->LUA_TNUMBER;
is $num1->is_number, 1;
