# lib/VM/Object/LocVar.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::LocVar;

use lib '../../';
use plua;

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'var_name',    #Str
        'start_pc', 'end_pc'
    );
}

1;
