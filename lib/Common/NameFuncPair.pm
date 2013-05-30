# lib/Common/NameFuncPair.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class Common::NameFuncPair {

    #-BUILD (func => CodeRef, name => Str)
    has 'func' => (
        is       => 'rw',
        isa      => 'CodeRef',
        required => 1,
    );

    has 'name' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );
}

1;
