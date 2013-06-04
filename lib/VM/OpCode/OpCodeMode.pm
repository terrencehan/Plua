# lib/VM/OpCode/OpCodeMode.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::OpCode::OpCodeMode;

#--BUILD(TMode => bool, AMode  => bool, BMode => OpArgMask, CMode => OpArgMask, OpMode => OpMode)

use lib '../../';
use VM::OpCode::OpArgMask;
use VM::OpCode::OpMode;

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

1;
