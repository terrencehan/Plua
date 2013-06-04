# lib/VM/Object/LClosure.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::LClosure;

use strict;
use warnings;
use lib '../../';
use plua;
use VM::Common::ClosureType;
use VM::Common::LuaType;
use parent qw/VM::Object VM::Object::Closure/;

#-BUILD (proto => VM::Object::Proto)

BEGIN {
    my $class = __PACKAGE__;
    attr( $class, undef, 
        'proto' #'VM::Object::Proto
    );
    attr( $class, [], 
        'upvals' #'ArrayRef[VM::Object::Upvalue]',
    );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->is_function(1);
    $self->is_clousre(1);
    $self->type( VM::Common::LuaType->LUA_TFUNCTION );
    $self->closure_type( VM::Common::ClosureType->LUA );
    for ( @{ $self->proto->upvalues } ) {
        push $self->upvals, undef;
    }
    return $self;
}

sub get_upvalue {
    my (
        $self,
        $n,       #Num
        $val      #ScalarRef [VM::Object]
    ) = @_;
    if ( !( 1 <= $n && $n <= scalar @{ $self->upvals } ) ) {
        $$val = undef;
        return undef;
    }
    else {
        $$val = $self->upvals->[ $n - 1 ]->v->value;
        my $name = $self->proto->upvalues->[ $n - 1 ]->name;
        return ( defined $name ) ? $name : '';
    }
}

sub set_upvalue {
    my (
        $self,
        $n,     #Num
        $val    #ScalarRef [VM::Object]
    ) = @_;
    if ( !( 1 <= $n && $n <= scalar @{ $self->upvals } ) ) {
        $$val = undef;
        return undef;
    }
    else {
        $self->upvals->[ $n - 1 ]->v->value($val);
        my $name = $self->proto->upvalues->[ $n - 1 ]->name;
        return ( defined $name ) ? $name : '';
    }
}

1;
