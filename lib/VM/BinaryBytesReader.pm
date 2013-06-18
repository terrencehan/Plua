# lib/VM/BinaryBytesReader.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::BinaryBytesReader;

#-BUILD (load_info => VM::LoadInfo)
use lib '../';
use plua;
use aliased 'Helper::BitConverter';

BEGIN {
    my $class = __PACKAGE__;

    attr( $class, undef, qw/ load_info / );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    return $self;
}

sub read_bytes {
    my (
        $self,
        $count,    #Int
    ) = @_;
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

sub read_int {
    my $self = shift;
    return Helper::BitConverter->to_int32( $self->read_bytes(4) );
}

sub read_uint {
    my $self = shift;
    return Helper::BitConverter->to_uint32( $self->read_bytes(4) );
}

sub read_size_t {
    my $self = shift;
    $self->read_uint;    #need more scalable
}

sub read_double {
    my $self = shift;
    return Helper::BitConverter->to_double( $self->read_bytes(8) );
}

sub read_byte {
    my $self = shift;
    my $c    = $self->load_info->read_byte();
    if ( $c == -1 ) {
        die "thruncated";
    }
    return $c;
}

sub read_string {
    my $self = shift;
    my $n    = $self->read_size_t();
    if ( $n == 0 ) {
        return undef;
    }
    my @bytes = $self->read_bytes($n);

    pop @bytes;

    my $ret = pack "C*", @bytes;
    return $ret;
}

1;
