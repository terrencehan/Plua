# t/02-vm-object.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use VM::Object::Number;
BEGIN { use_ok('VM::Object') }

my $o = VM::Object->new;

isa_ok $o->as('VM::Object'),  'VM::Object';
is $o->as('VM::Object::Nil'), undef;

my $num = new VM::Object::Number( value => 1 );

isa_ok $num->as('VM::Object'),         'VM::Object';
isa_ok $num->as('VM::Object::Number'), 'VM::Object::Number';
is $num->as('VM::Object::String'),     undef;

done_testing;
