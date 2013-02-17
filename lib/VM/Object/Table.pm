# lib/VM/Object/Table.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class Node {

    #-BUILD (key => VM::Object, value => VM::Object)
    has [qw/key value/] => (
        is  => 'rw',
        isa => 'VM::Object',
    );
    has [qw/prev next/] => (
        is  => 'rw',
        isa => 'Node',
    );
}

class VM::Object::Table extends VM::Object {

    #-BUILD (array_size => Int, dict_size => Int)
    use lib '../../';
    use VM::Type;
    use VM::Object;
    use VM::Object::Number;
    use VM::Object::String;

    has dict_part => (
        is      => 'rw',
        isa     => 'HashRef[VM::Object]',
        default => sub { {} },
    );

    has head => (
        is  => 'rw',
        isa => 'Node',
    );

    has meta_table => (
        is  => 'rw',
        isa => 'VM::Object::Table',

        #default => sub { VM::Object::Table->new }, #TODO
    );

    has flags => (    # no tag method flags
        is      => 'rw',
        isa     => 'Int',
        default => ~0,
    );

    has cached_length => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    has cached_length_dirty => (
        is      => 'rw',
        isa     => 'Bool',
        default => 0,
    );

    #method length {
    ##TODO
    #}

    method BUILD ($args) {
        my $array_size = $args->{array_size} or 0;
        my $dict_size  = $args->{dict_size}  or 0;
        $self->type( VM::Type->LUA_TTABLE );
        $self->is_table(1);

        #TODO
    }

    method _update_length_on_remove (VM::Object $key) {

    }

    method _update_length_on_append (VM::Object $key) {
    }

    method _remove (VM::Object $key) {
        my $old;                      #Node
        if ( $old = $self->dict_part->{$key} ) {
            $self->head( $old->next )      if $self->head == $old;
            $old->prev->next( $old->next ) if defined $old->prve;
            $old->next->prev( $old->prev ) if defined $old->next;
            delete $self->dict_part->{$key};
            $self->_update_length_on_remove($key);
        }
    }

    method _set (VM::Object $key, VM::Object $val) {
        my $vnode = Node->new( key => $key, value => $val );
        my $old;    #Node
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

    method set (VM::Object $key, VM::Object $val) {
        if ( $val->is_nil ) {
            $self->_remove($key);
        }
        else {
            $self->_set( $key, $val );
        }

        $self->flags = 0;
    }

    method get (VM::Object $key) {
        my $node;    #Node
        if ( $node = $self->dict_part->{$key} ) {
            return $node->value;
        }
        return VM::Object::Nil->new;
    }

    method set_int (Int $key, VM::Object $val) {
        $self->set( VM::Object::Number->new( value => $key ), $val );
    }

    method get_int (Int $key) {
        $self->get( VM::Object::Number->new( value => $key ) );
    }

    method get_str (Str $key) {
        $self->get( VM::Object::String( value => $key ) );
    }
}

1;
