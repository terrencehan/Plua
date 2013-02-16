# t/05-vm-object-string.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More tests => 12;
use VM::Type;
BEGIN { use_ok('VM::Object::String') }

my $str1 = VM::Object::String->new( value => "ok" );
my $str2 = VM::Object::String->new( value => "ok" );

isa_ok $str1, 'VM::Object::String';
isa_ok $str2, 'VM::Object::String';

is $str1 == $str2, 1;
is $str1 == undef, 0;
is undef == $str2, 0;

is $str1 != $str2, '';

$str2->value("notok");

is $str1 != $str2, 1;

is $str1 == $str2, '';

is $str1->to_string, '[LuaString(ok)]';
is $str1->is_string, 1;
is $str1->type, VM::Type->LUA_TSTRING;

