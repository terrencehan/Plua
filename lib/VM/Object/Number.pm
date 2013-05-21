# lib/VM/Object/Number.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::Number extends VM::Object {

    #-BUILD (value => Num)
    use lib '../../';
    use VM::Type;

    has value => (
        is       => 'rw',
        isa      => 'Num',
        required => 1,
    );

    method BUILD {
        $self->is_number(1);
        $self->type( VM::Type->LUA_TNUMBER );
    }

    override to_string {
        return "[LuaNumber(" . $self->value . ")]";
    }

    override to_num { $self->value; }

}

{

    package VM::Object::Number;
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
}

1;
