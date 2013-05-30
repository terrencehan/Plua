# lib/VM/BinaryBytesReader.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::BinaryBytesReader {

    #-BUILD (load_info => VM::LoadInfo)
    use aliased 'Helper::BitConverter';

    has 'load_info' => (
        is       => 'rw',
        isa      => 'VM::LoadInfo',
        required => 1,
    );

    method read_bytes (Int $count) {
        my @ret;
        for ( 0 .. $count - 1 ) {
            my $c = $self->load_info->read_byte();
            if ( $c == -1 ) {
                die "thruncated";
            }
            push @ret, $c;
        }
        return @ret;
    }

    method read_int {
        return Helper::BitConverter->to_int32( $self->read_bytes(4) );
    }

    method read_uint {
        return Helper::BitConverter->to_uint32( $self->read_bytes(4) );
    }

    method read_size_t {
        $self->read_uint;    #need more scalable
    }

    method read_double {
        return Helper::BitConverter->to_double( $self->read_bytes(8) );
    }

    method read_byte {
        my $c = $self->load_info->read_byte();
        if ( $c == -1 ) {
            die "thruncated";
        }
        return $c;
    }

    method read_string {
        my $n = $self->read_size_t();
        if ( $n == 0 ) {
            return undef;
        }
        my @bytes = $self->read_bytes($n);
        my $ret = pack "C*", @bytes;
        return $ret;
    }

}

1;
