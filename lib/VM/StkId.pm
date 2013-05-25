# lib/VM/StkId.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::StkId {

    #-BUILD (list => ArrayRef[VM::Object], index => Int | object => LuaObject | stkid => VM::StkId)

    use lib '../';
    use VM::Object;
    use VM::Object::Nil;
    has 'isolate_value' => (
        is  => 'rw',
        isa => 'VM::Object',
    );

    has 'index' => (
        is  => 'rw',
        isa => 'Int',
    );

    has 'list' => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object]',
        default => sub { [] },
    );

    method BUILD ($args) {
        my @keys = keys $args;
        if ( 'stkid' ~~ @keys ) {
            $self->list( $args->{stkid}->list );
            $self->index( $args->{stkid}->index );
        }
        elsif ( 'object' ~~ @keys ) {
            $self->index(0);
            $self->list( [] );
            $self->isolate_value( $args->{object} );
        }
    }

    method value ($val?) {
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

    method value_inc ($val?) {
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

    method is_null {
        return !defined( $self->list ) && !defined( $self->isolate_value );
    }

    method ensure_stack {
        while ( $self->index >= scalar @{ $self->list } ) {
            push $self->list, VM::Object::Nil->new();
        }
    }
}

{

    package VM::StkId;
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
}

1;
