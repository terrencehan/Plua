# t/10-vm-stkid.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

#use Test::More tests => 5;
use Test::More;
use VM::Type;
use VM::Object::Number;
BEGIN { use_ok('VM::StkId') }

my $stkid = new VM::StkId(
    list => [
        VM::Object::Number->new( value => 0 ),
        VM::Object::Number->new( value => 1 ),
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 3 ),
    ],
    index => 1
);

my $stkid2 = new VM::StkId(
    list => [
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 2 ),
    ],
    index => 1
);

isa_ok $stkid, 'VM::StkId';

is $stkid->is_null, '', 'is_null';

is $stkid == $stkid,  1,  'eq';
is $stkid == $stkid2, '', 'eq';
is $stkid != $stkid2, 1, 'neq';

is $stkid->index, 1, 'index is setted correctly';

$stkid = $stkid + 2;
is $stkid->index, 3, '+ ok';

$stkid = $stkid - 3;
is $stkid->index, 0, '- ok';

is $stkid->value->value,     0, 'method:value';
is $stkid->value_inc->value, 0, 'method:value';
is $stkid->value->value,     1, 'method:value';
is $stkid->value_inc->value, 1, 'method:value';
is $stkid->value->value,     2, 'method:value';
is $stkid->value_inc->value, 2, 'method:value';
is $stkid->value_inc->value, 3, 'method:value';
is $stkid->index, 4, 'index ok';
is scalar @{ $stkid->list }, 4, 'list size is 4';
is $stkid->value_inc->is_nil, 1, 'method:value';
is scalar @{ $stkid->list }, 5, 'list size is 5';

done_testing;
