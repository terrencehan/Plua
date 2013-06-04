# lib/VM/Object/Boolean.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::Boolean;

use lib '../../';
use VM::Common::LuaType;

use parent qw/VM::Object/;

#--BUILD(value => bool)

my @required = qw/value/;

sub new {
    my ($class, @args) = @_;
    my $self = bless {@args}, $class;
    $self->type( VM::Common::LuaType->LUA_TBOOLEAN );
    return $self;
}

sub value{
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        $self->is_false(!$val);
        return $self->{value} = $val;
    }
    else {
        return $self->{value};
    }
}

1;
