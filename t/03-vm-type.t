# t/03-vm-type.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More tests => 15;

use_ok 'VM::Type';

is VM::Type->LUA_TNONE,          -1;
is VM::Type->LUA_TNIL,           0;
is VM::Type->LUA_TBOOLEAN,       1;
is VM::Type->LUA_TLIGHTUSERDATA, 2;
is VM::Type->LUA_TNUMBER,        3;
is VM::Type->LUA_TSTRING,        4;
is VM::Type->LUA_TTABLE,         5;
is VM::Type->LUA_TFUNCTION,      6;
is VM::Type->LUA_TUSERDATA,      7;
is VM::Type->LUA_TTHREAD,        8;
is VM::Type->NUMTAGS,            9;
is VM::Type->LUA_TPROTO,         10;
is VM::Type->LUA_TUPVAL,         11;
is VM::Type->LUA_TDEADKEY,       12;
