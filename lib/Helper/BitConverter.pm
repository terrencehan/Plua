# lib/Helper/BitConverter.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package Helper::BitConverter;

sub to_int32 {
    my ( $class, @bytes ) = @_;
    if ( @bytes != 4 ) {
        die 'invalid size of @bytes';
    }
    return unpack "i", pack "C*", @bytes;
}

sub to_uint32 {
    my ( $class, @bytes ) = @_;
    if ( @bytes != 4 ) {
        die 'invalid size of @bytes';
    }
    return unpack "I", pack "C*", @bytes;
}

sub to_double {
    my ( $class, @bytes ) = @_;
    if ( @bytes != 8 ) {
        die 'invalid size of @bytes';
    }
    return unpack "d", pack "C*", @bytes;
}

1;
