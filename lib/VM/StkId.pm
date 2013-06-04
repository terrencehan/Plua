# lib/VM/StkId.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::StkId;

#-BUILD (list => ArrayRef[VM::Object], index => Int | object => LuaObject | stkid => VM::StkId)

use lib '../';
use VM::Object;
use VM::Object::Nil;

sub isolate_value {    #get/set
                       #'VM::Object
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        return $self->{value} = $val;
    }
    else {
        return $self->{value};
    }
}

sub index {            #get/set
                       #'Int
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        return $self->{index} = $val;
    }
    else {
        return $self->{index};
    }
}

sub list {             #get/set
                       #'ArrayRef[VM:Object]
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        return $self->{list} = $val;
    }
    else {
        return $self->{list};
    }
}

sub BUILDARGS {
    my %args = @_;
    my @keys = keys %args;
    if ( 'stkid' ~~ @keys ) {
        return (
            list  => $args{stkid}->list,
            index => $args{stkid}->index,
        );
    }
    elsif ( 'object' ~~ @keys ) {
        return (
            list          => undef,
            index         => 0,
            isolate_value => $args{object}
        );
    }
    else {
        return %args;
    }
}

sub new {
    my ( $class, @args ) = @_;
    @args = BUILDARGS @args;
    bless {@args}, $class;
}

sub value {
    my ( $self, $val ) = @_;
    if ( !defined $val ) {

        if ( defined $self->isolate_value ) {
            return $self->isolate_value;
        }
        $self->ensure_stack();
        return $self->list->[ $self->index ];
    }
    else {

        if ( defined $self->isolate_value ) {
            die;
        }
        $self->ensure_stack();
        return $self->list->[ $self->index ] = $val;
    }

}

sub value_inc {
    my ( $self, $val ) = @_;
    if ( !defined $val ) {

        if ( defined $self->isolate_value ) {
            die;
        }
        $self->ensure_stack();
        my $old_index = $self->index;
        $self->index( $old_index + 1 );
        return $self->list->[$old_index];
    }
    else {

        if ( defined $self->isolate_value ) {
            die;
        }
        $self->ensure_stack();
        my $old_index = $self->index;
        $self->index( $old_index + 1 );
        return $self->list->[$old_index] = $val;
    }
}

sub is_null {
    my ($self) = @_;
    return !defined( $self->list ) && !defined( $self->isolate_value );
}

sub ensure_stack {
    my ($self) = @_;
    while ( $self->index >= scalar @{ $self->list } ) {
        push $self->list, VM::Object::Nil->new();
    }
}

sub clone {
    my ($self) = @_;
    return VM::StkId->new( list => $self->list, index => $self->index );
}

use overload '==' => \&myeq;
use overload '!=' => \&myneq;
use overload '+'  => \&add;
use overload '-'  => \&sub;

sub myeq {
    my ( $one, $two ) = @_;

    if ( not( ( defined $one ) and ( defined $two ) ) ) {
        return 0;
    }

    return
         $one->index == $two->index
      && $one->list == $two->list
      && (
           defined( $one->isolate_value )
        && defined( $two->isolate_value )
        ? $one->isolate_value == $two->isolate_value
        : 1
      )
      && (
          !defined( $one->isolate_value )
        && defined( $two->isolate_value ) ? 0
        : 1
      )
      && (
        defined( $one->isolate_value )
        && !defined( $two->isolate_value ) ? 0
        : 1
      );
}

sub myneq {
    my ( $one, $two ) = @_;
    return not( $one == $two );
}

sub add {
    my ( $one, $two ) = @_;
    if ( defined( $one->isolate_value ) ) {
        die;
    }
    VM::StkId->new( list => $one->list, index => $one->index + $two );
}

sub sub {
    my ( $one, $two ) = @_;
    if ( defined( $one->isolate_value ) ) {
        die;
    }
    VM::StkId->new( list => $one->list, index => $one->index - $two );
}

1;
