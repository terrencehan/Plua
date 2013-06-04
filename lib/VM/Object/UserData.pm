# lib/VM/Object/UserData.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::UserData;

use lib '../../';
use plua;
use parent qw/VM::Object/;
use VM::Common::LuaType;

#-BUILD (value => Any)

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'value',         #Any
        'meta_table',    #VM::Object::Table
    );

    attr(
        $class, 0,
        'length',        #Int
    );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->type( VM::Common::LuaType->LUA_TUSERDATA );
    return $self;
}

1;
