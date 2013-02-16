# t/08-vm-object-boolean.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More tests => 5;
use VM::Type;
BEGIN { use_ok('VM::Object::Boolean') }

my $bool = VM::Object::Boolean->new( value => 1 );

isa_ok $bool, 'VM::Object::Boolean';

is $bool->is_false, '';
is $bool->type,     VM::Type->LUA_TBOOLEAN;

$bool->value(0);
is $bool->is_false, 1;
