# lib/VM/Object/Number.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::Number;

#-BUILD (value => Num)
use lib '../../';
use plua;
use VM::Common::LuaType;
use parent qw/VM::Object/;

my @required = qw/value/;

BEGIN {
    my $class = __PACKAGE__;
    attr( $class, undef, qw/ value / );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->is_number(1);
    $self->type( VM::Common::LuaType->LUA_TNUMBER );
    return $self;
}

sub to_string {
    my $self = shift;
    return "[LuaNumber(" . $self->value . ")]";
}

sub to_num {
    my $self = shift;
    $self->value;
}

use overload '==' => \&myeq;
use overload '!=' => \&myneq;
use overload '+'  => \&add;
use overload '-'  => \&sub;
use overload '*'  => \&mul;
use overload '/'  => \&div;
use overload '""' => \&str;

sub myeq {
    my ( $one, $two ) = @_;

    if ( not( ( defined $one ) and ( defined $two ) ) ) {
        return 0;
    }

    return $one->value == $two->value;
}

sub myneq {
    my ( $one, $two ) = @_;
    return not( $one == $two );
}

sub add {
    my ( $one, $two ) = @_;
    VM::Object::Number->new( value => ( $one->value + $two->value ) );
}

sub sub {
    my ( $one, $two ) = @_;
    VM::Object::Number->new( value => ( $one->value - $two->value ) );

}

sub mul {
    my ( $one, $two ) = @_;
    VM::Object::Number->new( value => ( $one->value * $two->value ) );

}

sub div {
    my ( $one, $two ) = @_;
    VM::Object::Number->new( value => ( $one->value / $two->value ) );
}

sub str {
    my $self = shift;
    return $self->to_num . "";
}

1;
