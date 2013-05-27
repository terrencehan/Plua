# lib/VM/StringLoadInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::StringLoadInfo extends VM::LoadInfo {

    #-BUILD (str => Str)
    has 'str' => (
        is  => 'rw',
        isa => 'Str',
    );
    has 'pos' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    method read_byte {
        if ( $self->pos >= length( $self->str ) ) {
            return -1;
        }
        else {
            my $old_pos = $self->pos;
            $self->pos( $self->pos + 1 );
            return substr( $self->str, $old_pos, 1 );
        }
    }

    method peek_byte {
        if ( $self->pos >= length( $self->str ) ) {
            return -1;
        }
        else {
            return substr( $self->str, $self->pos, 1 );
        }
    }
}

1;
