# lib/VM/OpCode/OpCodeMode.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::OpCode::OpCodeMode { 
     #--BUILD(TMode => bool, AMode  => bool, BMode => OpArgMask, CMode => OpArgMask, OpMode => OpMode)
    use lib '../../';
    use VM::OpCode::OpArgMask;
    use VM::OpCode::OpMode;
    has [ 'TMode', 'AMode' ] => (
        is  => 'rw',
        isa => 'Bool',
    );

    has [ 'BMode', 'CMode' ] => (
        is  => 'rw',
        #isa => 'VM::OpCode::OpArgMask',
        isa => 'Num', 
    );

    has OpMode => (
        is  => 'rw',
        #isa => 'VM::OpCode::OpMode'
        isa => 'Num', 
    );
}

1;
