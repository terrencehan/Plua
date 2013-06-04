# lib/VM/Object/Upvalue.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::Upvalue;
use lib '../../';
use plua;
use strict;
use warnings;
use parent qw/VM::Object/;
use VM::StkId;
use VM::Object::Nil;
use VM::Common::LuaType;

#-BUILD ()

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'v',    #VM::StkId
    );

    attr(
        $class, [],
        'value',    #ArrayRef[VM::Object]
    );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {}, $class;
    $self->type( VM::Common::LuaType->LUA_TUPVAL );
    push $self->value, VM::Object::Nil->new();
    $self->v( new VM::StkId( list => $self->value, index => 0 ) );
    return $self;
}

1;
