# lib/VM/Object/UpvalDesc.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::UpvalDesc;
use lib '../../';
use plua;

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'name',       #Str
        'index',      #Int
        'in_stack'    #Bool
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

1;
