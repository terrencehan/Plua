# lib/VM/Object/PClosure.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::PClosure;

use strict;
use warnings;
use lib '../../';
use plua;
use parent qw/VM::Object VM::Object::Closure/;

#-BUILD (f => CodeRef)
use VM::Common::ClosureType;
use VM::Common::LuaType;

BEGIN {
    my $class = __PACKAGE__;
    attr( $class, undef, 
        'f' #CodeRef
    );
    attr( $class, [], 
        'upvals' #'ArrayRef[VM::Object::Upvalue]',
    );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->closure_type( VM::Common::ClosureType->PERL );
    $self->is_function(1);
    $self->is_clousre(1);
    $self->type( VM::Common::LuaType->LUA_TFUNCTION );
    return $self;
}

sub get_upvalue {
    my (
        $self,
        $n,       #Num
        $val      #ScalarRef [VM::Object]
    ) = @_;
    if ( !( 1 <= $n && $n <= scalar @$self->upvals ) ) {
        $$val = undef;
        return undef;
    }
    else {
        $$val = $self->upvals->[ $n - 1 ];
        return '';
    }
}

sub set_upvalue {
    my (
        $self,
        $n,     #Num
        $val    #ScalarRef [VM::Object]
    ) = @_;
    if ( !( 1 <= $n && $n <= scalar @$self->upvals ) ) {
        return undef;
    }
    else {
        $self->upvals->[ $n - 1 ]($val);
        return '';
    }
}

1;
