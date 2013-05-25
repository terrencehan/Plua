# lib/VM/Pointer.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::Pointer {

    #-BUILD (list => ArrayRef[Any], index => Int | pointer => VM::Pointer)

    has 'list' => (
        is  => 'rw',
        isa => 'ArrayRef[Any]',
    );

    has 'index' => (
        is  => 'rw',
        isa => 'Int',
    );

    method BUILD ($args) {
        my @keys = keys $args;
        if ( 'pointer' ~~ @keys ) {
            $self->list  = $args->{pointer}->list;
            $self->index = $args->{pointer}->index;
        }
    }

    method value ($val?) {
        if ( !defined $val ) {    #get
            return $self->list->[ $self->index ];
        }
        else {                    #set
            $self->list->[ $self->index ] = $val;
        }
    }

    method value_inc ($val?) {
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
}

{

    package VM::Pointer;

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
}

1;
