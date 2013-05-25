# t/03-vm-type.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;

use_ok 'VM::Common::LuaType';
use aliased 'VM::Common::LuaType';

is LuaType->LUA_TNONE,          -1;
is LuaType->LUA_TNIL,           0;
is LuaType->LUA_TBOOLEAN,       1;
is LuaType->LUA_TLIGHTUSERDATA, 2;
is LuaType->LUA_TNUMBER,        3;
is LuaType->LUA_TSTRING,        4;
is LuaType->LUA_TTABLE,         5;
is LuaType->LUA_TFUNCTION,      6;
is LuaType->LUA_TUSERDATA,      7;
is LuaType->LUA_TTHREAD,        8;
is LuaType->NUMTAGS,            9;
is LuaType->LUA_TPROTO,         10;
is LuaType->LUA_TUPVAL,         11;
is LuaType->LUA_TDEADKEY,       12;

use aliased 'VM::Common::LuaOp';
is LuaOp->LUA_OPADD, 0;
is LuaOp->LUA_OPSUB, 1;
is LuaOp->LUA_OPMUL, 2;
is LuaOp->LUA_OPDIV, 3;
is LuaOp->LUA_OPMOD, 4;
is LuaOp->LUA_OPPOW, 5;
is LuaOp->LUA_OPUNM, 6;

done_testing;
