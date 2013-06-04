# lib/VM/CallS.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::CallS;

use lib '../';
use plua;

#-BUILD (func => VM::StkId, num_results => Int)
BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, [],
        'func',           #VM::StkId
        'num_results',    #Int
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

1;
