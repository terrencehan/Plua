# lib/VM/Common/LuaDef.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Common::LuaDef {
    use MooseX::ClassAttribute;
    use aliased 'VM::Common::LuaConf';

    my %h;
    $h{LUA_MINSTACK} = 20;

    $h{LUA_RIDX_MAINTHREAD} = 1;
    $h{LUA_RIDX_GLOBALS}    = 2;
    $h{LUA_RIDX_LAST}       = $h{LUA_RIDX_GLOBALS};

    $h{LUA_MULTRET} = -1;

    $h{LUA_REGISTRYINDEX} = LuaConf->LUAI_FIRSTPSEUDOIDX;

    # number of list items accumulate before a SETLIST instruction
    $h{LFIELDS_PER_FLUSH} = 50;

    $h{LUA_IDSIZE} = 60;

    $h{LUA_VERSION_MAJOR} = '5';
    $h{LUA_VERSION_MINOR} = '2';    #TODO
    $h{LUA_VERSION} =
      "Lua " . $h{LUA_VERSION_MAJOR} . '.' . $h{LUA_VERSION_MINOR};

    $h{LUA_ENV} = "_ENV";

    for ( keys %h ) {
        class_has $_ => (
            is      => 'ro',
            default => $h{$_},
        );
    }
}

1;
