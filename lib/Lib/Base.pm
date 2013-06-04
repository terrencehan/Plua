# lib/Lib/Base.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package  Lib::Base;

use lib '../';
use aliased 'Common::NameFuncPair';
use aliased 'VM::Common::LuaDef';

sub LIB_NAME { return '_G'; }

sub open_lib {
    my (
        $class,
        $lua,    #VM::State
    ) = @_;
    my @define = (
        NameFuncPair->new(
            name => 'assert',
            func => sub { Lib::Base->b_assert(@_); }
        ),

        NameFuncPair->new(
            name => 'collectgarbage',
            func => sub { Lib::Base->b_collect_garbage(@_); }
        ),

        NameFuncPair->new(
            name => 'dofile',
            func => sub { Lib::Base->b_do_file(@_); }
        ),

        NameFuncPair->new(
            name => 'error',
            func => sub { Lib::Base->b_error(@_); }
        ),

        NameFuncPair->new(
            name => 'ipairs',
            func => sub { Lib::Base->b_ipairs(@_); }
        ),

        NameFuncPair->new(
            name => 'loadfile',
            func => sub { Lib::Base->b_load_file(@_); }
        ),

        NameFuncPair->new(
            name => 'load',
            func => sub { Lib::Base->b_load(@_); }
        ),

        NameFuncPair->new(
            name => 'loadstring',
            func => sub { Lib::Base->b_load(@_); }
        ),

        NameFuncPair->new(
            name => 'next',
            func => sub { Lib::Base->b_next(@_); }
        ),

        NameFuncPair->new(
            name => 'pairs',
            func => sub { Lib::Base->b_pairs(@_); }
        ),

        NameFuncPair->new(
            name => 'pcall',
            func => sub { Lib::Base->b_p_call(@_); }
        ),

        NameFuncPair->new(
            name => 'print',
            func => sub { Lib::Base->b_print(@_); }
        ),

        NameFuncPair->new(
            name => 'rawequal',
            func => sub { Lib::Base->b_raw_equal(@_); }
        ),

        NameFuncPair->new(
            name => 'rawlen',
            func => sub { Lib::Base->b_raw_len(@_); }
        ),

        NameFuncPair->new(
            name => 'rawget',
            func => sub { Lib::Base->b_raw_get(@_); }
        ),

        NameFuncPair->new(
            name => 'rawset',
            func => sub { Lib::Base->b_raw_set(@_); }
        ),

        NameFuncPair->new(
            name => 'select',
            func => sub { Lib::Base->b_select(@_); }
        ),

        NameFuncPair->new(
            name => 'getmetatable',
            func => sub { Lib::Base->b_get_meta_table(@_); }
        ),

        NameFuncPair->new(
            name => 'setmetatable',
            func => sub { Lib::Base->b_set_meta_table(@_); }
        ),

        NameFuncPair->new(
            name => 'tonumber',
            func => sub { Lib::Base->b_to_number(@_); }
        ),

        NameFuncPair->new(
            name => 'tostring',
            func => sub { Lib::Base->b_to_string(@_); }
        ),

        NameFuncPair->new(
            name => 'type',
            func => sub { Lib::Base->b_type(@_); }
        ),

        NameFuncPair->new(
            name => 'xpcall',
            func => sub { Lib::Base->b_x_p_call(@_); }
        ),
    );

    #set global _G
    $lua->push_global_table();
    $lua->push_global_table();
    $lua->set_field( -2, "_G" );

    #open lib into global lib
    $lua->l_set_funcs( \@define, 0 );

    $lua->push_string( LuaDef->LUA_VERSION );
    $lua->set_field( -2, "_VERSION" );

    return 1;
}

sub b_assert {
    die '#TODO';
}

1;
