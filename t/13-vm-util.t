# t/13-vm-util.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;

use VM::Object;
use VM::Object::Number;
use_ok 'VM::Util';

#local $SIG{__DIE__} = sub {
#print 'ok';
#return;
#};

#VM::Util->assert(0);
#VM::Util->api_check(1,'hello');

my $pos = 0;
is VM::Util->str2number( "123.123ab", \$pos ), 123.123;
is $pos, 7;

$pos = 0;
is VM::Util->str2number( "  123.123ab", \$pos ), 123.123;
is $pos, 9;

$pos = 0;
is VM::Util->str2number( "  123123ab", \$pos ), 123123;
is $pos, 8;

$pos = 0;
is VM::Util->str2number( "123.123e1ab", \$pos ), 1231.23;
is $pos, 9;

$pos = 0;
is VM::Util->str2number( "123.123E1ab", \$pos ), 1231.23;
is $pos, 9;

$pos = 0;
is VM::Util->str2number( "ab", \$pos ), 0;
is $pos, 0;

$pos = 0;
is VM::Util->strX2number( "0xa", \$pos ), 10;
is $pos, 3;

$pos = 0;
is VM::Util->strX2number( "0x1a", \$pos ), 26;
is $pos, 4;

$pos = 0;
is VM::Util->strX2number( "0x1a.1", \$pos ), 26.0625;
is $pos, 6;

$pos = 0;
is VM::Util->strX2number( " 0x1a.1", \$pos ), 26.0625;
is $pos, 7;

$pos = 0;
is VM::Util->strX2number( "0xaP1", \$pos ), 20;
is $pos, 5;

my $o = VM::Object->new;

use aliased 'VM::Util';

isa_ok Util->as( $o, 'VM::Object' ), 'VM::Object';
is Util->as( $o, 'VM::Object::Nil' ), undef;

my $num = new VM::Object::Number( value => 1 );

isa_ok Util->as( $num, 'VM::Object' ),         'VM::Object';
isa_ok Util->as( $num, 'VM::Object::Number' ), 'VM::Object::Number';
is Util->as( $num,  'VM::Object::String' ), undef;
is Util->as( undef, 'VM::Object::String' ), undef;

done_testing;
