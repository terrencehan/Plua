# lib/VM/Object.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use v5.10;

package VM::Object;
use lib '../';
use plua;
use VM::Common::LuaType;

BEGIN {
    my $class = __PACKAGE__;

    attr(
        $class,
        0,
        qw/
          is_nil
          is_false
          is_function
          is_clousre
          is_string
          is_number
          is_table
          is_thread
          /
    );
    attr( $class, undef, qw/ type / );
}

sub new {
    my $class = shift;
    bless { type => VM::Common::LuaType->LUA_TNONE }, $class;
}

sub to_string { }

sub to_literal {
    my $self = shift;
    $self->to_string;
}
sub to_num { return 0.0; }

1;
