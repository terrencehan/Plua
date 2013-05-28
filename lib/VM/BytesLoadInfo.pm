# lib/VM/BytesLoadInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::BytesLoadInfo extends VM::LoadInfo {

    #-BUILD (bytes => bytes)
    has 'bytes' => ( is => 'rw', );    #isa bytes_array
    has 'pos' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    method read_byte {
        if ( $self->pos >= length( $self->bytes ) ) {    #TODO: length
            return -1;
        }
        else {
            my $old_pos = $self->pos;
            $self->pos( $self->pos + 1 );
            return vec( $self->bytes, $old_pos, 8 );
        }
    }

    method peek_byte ($len = 1){
        if ( $self->pos >= length( $self->bytes ) ) {    #TODO: length
            return -1;
        }
        else {
            return vec( $self->bytes, $self->pos, 8 * $len );
        }
    }
}

1;
