# lib/VM/StringLoadInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::StringLoadInfo;
use parent qw/VM::LoadInfo/;

#-BUILD (str => Str)

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

sub str {    #get/set
             #'Int
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        return $self->{str} = $val;
    }
    else {
        if ( defined $self->{str} ) {
            return $self->{str};
        }
        else {    #default
            return undef;
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
    my $self = shift;
    if ( $self->pos >= length( $self->str ) ) {
        return -1;
    }
    else {
        my $old_pos = $self->pos;
        $self->pos( $self->pos + 1 );
        return substr( $self->str, $old_pos, 1 );
    }
}

sub peek_byte {
    my $self = shift;
    if ( $self->pos >= length( $self->str ) ) {
        return -1;
    }
    else {
        return substr( $self->str, $self->pos, 1 );
    }
}

1;
