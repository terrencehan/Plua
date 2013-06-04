# lib/Common/NameFuncPair.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
package Common::NameFuncPair;

#-BUILD (func => CodeRef, name => Str)
use lib '../';
use plua;

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'func',    #CodeRef
        'name',    #Str
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

1;
