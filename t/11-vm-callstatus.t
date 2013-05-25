# t/11-vm-callstatus.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;

use_ok 'VM::CallStatus';

is VM::CallStatus->CIST_NONE,    0;
is VM::CallStatus->CIST_LUA,     0b1;
is VM::CallStatus->CIST_HOOKED,  0b10;
is VM::CallStatus->CIST_REENTRY, 0b100;
is VM::CallStatus->CIST_YIELDED, 0b1000;
is VM::CallStatus->CIST_YPCALL,  0b10000;
is VM::CallStatus->CIST_STAT,    0b100000;
is VM::CallStatus->CIST_TAIL,    0b1000000;
done_testing;
