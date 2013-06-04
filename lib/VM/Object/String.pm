# lib/VM/Object/String.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::String;

#-BUILD (value => Str)

use lib '../../';
use parent qw/VM::Object/;

my @required = qw/value/;

use plua;
use VM::Common::LuaType;

BEGIN {
    my $class = __PACKAGE__;
    attr( $class, undef, qw/ value / );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;

    $self->type( VM::Common::LuaType->LUA_TSTRING );
    $self->is_string(1);
    return $self;
}

sub to_string {
    my $self = shift;
    return "[LuaString(" . $self->value . ")]";
}

use overload '==' => \&myeq;
use overload '!=' => \&myneq;
use overload '""' => \&str;

sub myeq {
    my ( $one, $two ) = @_;

    if ( not( ( defined $one ) and ( defined $two ) ) ) {
        return 0;
    }

    return $one->value eq $two->value;
}

sub myneq {
    my ( $one, $two ) = @_;
    return not( $one == $two );
}

sub str {
    my $self = shift;
    return $self->value;
}

1;
