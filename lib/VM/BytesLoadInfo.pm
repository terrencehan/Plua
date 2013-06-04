# lib/VM/BytesLoadInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::BytesLoadInfo;

use lib '../';
use plua;
#-BUILD (bytes => bytes)

use parent qw/VM::LoadInfo/;

BEGIN {
    my $class = __PACKAGE__;
    attr( $class, [], 'bytes' );
    attr( $class, 0, 'pos');
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
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
