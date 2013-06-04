# lib/VM/Object/Nil.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::Nil;

use parent qw/VM::Object/;
use VM::Common::LuaType;

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->is_nil(1);
    $self->is_false(1);
    $self->type( VM::Common::LuaType->LUA_TNIL );
    return $self;
}

1;
