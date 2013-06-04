# lib/VM/Object/Table.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package Node;

#-BUILD (key => VM::Object, value => VM::Object)
use lib '../../';
use plua;

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'key',  'value',    #VM::Object
        'prev', 'next',     #VM::Node | Undef
    );
}

package VM::Object::Table;

#-BUILD (array_size => Int, dict_size => Int)
use lib '../../';
use plua;
use VM::Common::LuaType;
use VM::Object;
use VM::Object::Number;
use VM::Object::String;
use parent qw/VM::Object/;

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, {},
        'dict_part',    #HashRef[VM::Object]
    );

    attr(
        $class, undef,
        'head',          #Node
        'meta_table',    #VM::Object::Table
    );

    attr(
        $class, ~0,
        'flags',         #Int
    );

    attr(
        $class, 0,
        'cached_length',          #Int
        'cached_length_dirty',    #Bool
    );
}

#method length {
##TODO
#}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->type( VM::Common::LuaType->LUA_TTABLE );
    $self->is_table(1);
    return $self;
}

sub _update_length_on_remove {
    my (
        $self, $key    #VM::Object
    ) = @_;

}

sub _update_length_on_append {
    my (
        $self, $key    #VM::Object
    ) = @_;
}

sub _remove {
    my (
        $self, $key    #VM::Object
    ) = @_;
    my $old;           #Node
    if ( $old = $self->dict_part->{$key} ) {
        $self->head( $old->next )      if $self->head == $old;
        $old->prev->next( $old->next ) if defined $old->prve;
        $old->next->prev( $old->prev ) if defined $old->next;
        delete $self->dict_part->{$key};
        $self->_update_length_on_remove($key);
    }
}

sub _set {
    my (
        $self, $key    #VM::Object
        , $val         #VM::Object
    ) = @_;
    my $vnode = Node->new( key => $key, value => $val );
    my $old;           #Node
    if ( $old = $self->dict_part->{$key} ) {
        $self->head($vnode) if $self->head == $old;
        $vnode->prev( $old->prev );
        $vnode->next( $old->next );
        $old->prev->next($vnode) if defined $old->prev;
        $old->next->prev($vnode) if defined $old->next;
    }
    else {
        $vnode->next( $self->head );
        $self->head->prev($vnode) if defined $self->head;
        $self->head($vnode);

        $self->_update_length_on_append($key);
    }

    $self->dict_part->{$key} = $vnode;
}

sub set {
    my (
        $self, $key    #VM::Object
        , $val         #VM::Object
    ) = @_;
    if ( $val->is_nil ) {
        $self->_remove($key);
    }
    else {
        $self->_set( $key, $val );
    }

    $self->flags(0);
}

sub get {
    my (
        $self, $key    #VM::Object
    ) = @_;
    my $node;          #Node
    if ( $node = $self->dict_part->{$key} ) {
        return $node->value;
    }
    return VM::Object::Nil->new;
}

sub set_int {
    my (
        $self, $key,    #Int
        $val            #VM::Object
    ) = @_;
    $self->set( VM::Object::Number->new( value => $key ), $val );
}

sub get_int {
    my (
        $self, $key     #Int
    ) = @_;
    $self->get( VM::Object::Number->new( value => $key ) );
}

sub get_str {
    my (
        $self, $key     #Str
    ) = @_;
    $self->get( VM::Object::String->new( value => $key ) );
}

1;
