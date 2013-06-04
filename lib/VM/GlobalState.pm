# lib/VM/GlobalState.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::GlobalState;
use lib '../';
use plua;

#-BUILD (state => VM::State)
use VM::Object::Table;
use VM::Object::Upvalue;
use VM::State;
use aliased 'VM::Common::LuaType';

BEGIN {
    my $class = __PACKAGE__;
    attr( $class, VM::Object::Table->new, 'registy' );

    attr( $class, VM::Object::Upvalue->new, 'upval_head' );

    attr(
        $class, [],
        'meta_tables'    #ArrayRef[VM::Object::Table
    );

    attr(
        $class, undef,
        'man_thread'     #VM::State
    );
}

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->man_thread( $args{state} );
    return $self;
}

1;
