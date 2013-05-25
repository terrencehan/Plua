# t/11-vm-callstatus.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;

use_ok 'VM::Pointer';
use VM::Object::Number;

my $pointer = new VM::Pointer(
    list => [
        VM::Object::Number->new( value => 0 ),
        VM::Object::Number->new( value => 1 ),
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 3 ),
    ],
    index => 1
);

my $pointer2 = new VM::Pointer(
    list => [
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 2 ),
        VM::Object::Number->new( value => 2 ),
    ],
    index => 1
);

isa_ok $pointer, 'VM::Pointer';

is $pointer->index, 1, 'index is setted correctly';

$pointer = $pointer + 2;
is $pointer->index, 3, '+ ok';

$pointer = $pointer - 3;
is $pointer->index, 0, '- ok';

is $pointer->value->value,     0, 'method:value';
is $pointer->value_inc->value, 0, 'method:value';
is $pointer->value->value,     1, 'method:value';
is $pointer->value_inc->value, 1, 'method:value';
is $pointer->value->value,     2, 'method:value';
is $pointer->value_inc->value, 2, 'method:value';
is $pointer->value_inc->value, 3, 'method:value';
is $pointer->index, 4, 'index ok';
is scalar @{ $pointer->list }, 4, 'list size is 4';

done_testing;
