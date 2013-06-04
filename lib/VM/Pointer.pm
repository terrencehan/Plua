# lib/VM/Pointer.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
package VM::Pointer;
use lib '../';
use plua;

#-BUILD (list => ArrayRef[Any], index => Int | pointer => VM::Pointer)

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'list',     #ArrayRef[Any]
        'index',    #Int
    );
}

sub new {
    my ( $class, %args ) = @_;
    my @keys = keys %args;
    my $self;
    if ( 'pointer' ~~ @keys ) {
        $self = bless {}, $class;
        $self->list  = $args{pointer}->list;
        $self->index = $args{pointer}->index;
    }
    else {
        $self = bless {%args}, $class;
    }
    return $self;
}

sub value {
    my ( $self, $val ) = @_;
    if ( !defined $val ) {    #get
        return $self->list->[ $self->index ];
    }
    else {                    #set
        $self->list->[ $self->index ] = $val;
    }
}

sub value_inc {
    my ( $self, $val ) = @_;
    if ( !defined $val ) {    #get
        my $old_index = $self->index;
        $self->index( $old_index + 1 );
        return $self->list->[$old_index];
    }
    else {                    #set
        my $old_index = $self->index;
        $self->index( $old_index + 1 );
        $self->list->[$old_index] = $val;
    }
}

use overload '+' => \&add;
use overload '-' => \&sub;

sub add {
    my ( $one, $two ) = @_;
    VM::Pointer->new( list => $one->list, index => $one->index + $two );
}

sub sub {
    my ( $one, $two ) = @_;
    VM::Pointer->new( list => $one->list, index => $one->index - $two );
}

1;
