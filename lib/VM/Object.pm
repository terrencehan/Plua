# lib/VM/Object.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use v5.10;

package VM::Object;

use VM::Common::LuaType;

sub new {
    my $class = shift;
    bless { type => VM::Common::LuaType->LUA_TNONE }, $class;
}

BEGIN {
    my $class = __PACKAGE__ ;
    for my $func_name (
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
      )
    {
        *t = eval { "*" . $class . "::" . $func_name };
        *t = sub {
            my ( $self, $val ) = @_;
            if ( defined $val ) {
                return $self->{$func_name} = $val;
            }
            else {
                if ( !defined $self->{$func_name} ) {
                    return $self->{$func_name} = 0;
                }
                else {
                    return $self->{$func_name};
                }
            }
        };
    }

}

sub type {
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        return $self->{type} = $val;
    }
    else {
        return $self->{type};
    }
}

sub to_string { }

sub to_literal {
    my $self = shift;
    $self->to_string;
}
sub to_num { return 0.0; }

1;
