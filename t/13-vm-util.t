# t/11-vm-callstatus.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;

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

done_testing;
