# t/02-vm-object.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use VM::Object::Number;
use aliased 'VM::Util';
BEGIN { use_ok('VM::Object') }

my $o = VM::Object->new;

isa_ok Util->as( $o, 'VM::Object' ), 'VM::Object';
is Util->as( $o, 'VM::Object::Nil' ), undef;

my $num = new VM::Object::Number( value => 1 );

isa_ok Util->as( $num, 'VM::Object' ),         'VM::Object';
isa_ok Util->as( $num, 'VM::Object::Number' ), 'VM::Object::Number';
is Util->as( $num, 'VM::Object::String' ), undef;

done_testing;
