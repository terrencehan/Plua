# lib/VM/BytesLoadInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::BytesLoadInfo extends VM::LoadInfo {

    #-BUILD (bytes => bytes)
    has 'bytes' => (    #isa bytes_array
        is      => 'rw',
        isa     => 'ArrayRef',
        default => sub { [] },
    );
    has 'pos' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    method read_byte {
        if ( $self->pos >= @{ $self->bytes } ) {
            return -1;
        }
        else {
            my $old_pos = $self->pos;
            $self->pos( $self->pos + 1 );
            return $self->bytes->[$old_pos];
        }
    }

    method peek_byte ($len = 1) {
        if ( $self->pos >= @{ $self->bytes } ) {
            return -1;
        }
        else {
            return @{ $self->bytes }[ $self->pos .. $self->pos + --$len ];
        }
    }
}

1;
