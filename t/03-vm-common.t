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

use aliased 'VM::Common::LuaConf';
is LuaConf->LUAI_BITSINT,        32;
is LuaConf->LUAI_MAXSTACK,       1000000;
is LuaConf->LUAI_FIRSTPSEUDOIDX, -1000000 - 1000;
is LuaConf->LUA_SIGNATURE,       "\u001bLua";
is LuaConf->LUA_DIRSEP,          "/";

use aliased 'VM::Common::LuaDef';
is LuaDef->LUA_MINSTACK,        20;
is LuaDef->LUA_RIDX_MAINTHREAD, 1;
is LuaDef->LUA_RIDX_GLOBALS,    2;
is LuaDef->LUA_RIDX_LAST,       2;
is LuaDef->LUA_MULTRET,         -1;
is LuaDef->LUA_REGISTRYINDEX,   LuaConf->LUAI_FIRSTPSEUDOIDX;
is LuaDef->LFIELDS_PER_FLUSH,   50;
is LuaDef->LUA_IDSIZE,          60;
is LuaDef->LUA_VERSION_MAJOR,   "5";
is LuaDef->LUA_VERSION_MINOR,   "2";                            #TODO
is LuaDef->LUA_VERSION,         "Lua 5.2";                      #TODO
is LuaDef->LUA_ENV,             "_ENV";

use aliased 'VM::Common::LuaConstants';
is LuaConstants->LUA_NOREF,  -2;
is LuaConstants->LUA_REFNIL, -1;

use aliased 'VM::Common::LuaLimits';
is LuaLimits->MAX_INT,        0b01111111_11111111_11111111_11111111 - 2;
is LuaLimits->MAXUPVAL,       0b11111111;
is LuaLimits->LUAI_MAXCCALLS, 200;
is LuaLimits->MAXSTACK,       250;

done_testing;
