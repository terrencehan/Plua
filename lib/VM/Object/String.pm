# lib/VM/Object/String.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::String extends VM::Object {

    #-BUILD (value => Str)
    use VM::Common::LuaType;

    use lib '../../';
    has value => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    method BUILD {
        $self->is_string(1);
        $self->type( VM::Common::LuaType->LUA_TSTRING );
    }

    override to_string {
        return "[LuaString(" . $self->value . ")]";
    }
}

{
    #for overload
    package VM::Object::String;
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
}

1;
