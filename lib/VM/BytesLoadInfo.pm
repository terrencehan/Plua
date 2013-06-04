# lib/VM/BytesLoadInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::BytesLoadInfo;

#-BUILD (bytes => bytes)

use parent qw/VM::LoadInfo/;

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

sub bytes {    #get/set
               #'ArrayRef
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        return $self->{bytes} = $val;
    }
    else {
        if ( defined $self->{bytes} ) {
            return $self->{bytes};
        }
        else {    #default
            return $self->{bytes} = [];
        }
    }
}

sub pos {         #get/set
                  #'Int
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        return $self->{pos} = $val;
    }
    else {
        if ( defined $self->{pos} ) {
            return $self->{pos};
        }
        else {    #default
            return 0;
        }
    }
}

sub read_byte {
    my ($self) = @_;
    if ( $self->pos >= @{ $self->bytes } ) {
        return -1;
    }
    else {
        my $old_pos = $self->pos;
        $self->pos( $self->pos + 1 );
        return $self->bytes->[$old_pos];
    }
}

sub peek_byte {
    my ( $self, $len ) = @_;
    if ( !defined $len ) {
        $len = 1;
    }
    if ( $self->pos >= @{ $self->bytes } ) {
        return -1;
    }
    else {
        return @{ $self->bytes }[ $self->pos .. $self->pos + --$len ];
    }
}

1;
