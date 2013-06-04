# lib/VM/RuntimeException.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::RuntimeException;
use lib '../';
use plua;

BEGIN {
    my $class = __PACKAGE__;

    attr(
        $class, undef,
        'err_code'    #Int
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

1;
