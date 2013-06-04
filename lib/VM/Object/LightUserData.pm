# lib/VM/Object/LightUserData.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::LightUserData;
use lib '../../';
use VM::Common::LuaType;

#-BUILD (value => Any)

use parent qw/VM::Object/;

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->type( VM::Common::LuaType->LUA_TLIGHTUSERDATA );
    return $self;
}

sub value {    #get
    my $self = shift;
    return $self->{value};
}

1;
