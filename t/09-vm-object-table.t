# t/09-vm-object-table.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

#use Test::More tests => 5;
use Test::More;
use VM::Type;
use VM::Object::Number;
BEGIN { use_ok('VM::Object::Table') }

my $t = VM::Object::Table->new;
isa_ok $t, 'VM::Object::Table';

is $t->is_table, 1;
is $t->type,     VM::Type->LUA_TTABLE;

$t->set_int( 2, VM::Object::Number->new( value => 23 ) );
is $t->get_int(2)->to_num, 23;
is $t->get_str('2')->to_num, 23;

done_testing;
