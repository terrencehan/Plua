# lib/Coder/Instruction.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Instruction {

    #--BUILD(value => Int)

    use MooseX::ClassAttribute;

    has 'value' => (
        is     => 'rw',
        isa    => 'Int',
        reader => 'to_uint',
    );

    #class variable
    our $SIZE_C      = 9;
    our $SIZE_B      = 9;
    our $SIZE_Bx     = ( $SIZE_C + $SIZE_B );
    our $SIZE_A      = 8;
    our $SIZE_Ax     = ( $SIZE_C + $SIZE_B + $SIZE_A );
    our $SIZE_OP     = 6;
    our $POS_OP      = 0;
    our $POS_A       = ( $POS_OP + $SIZE_OP );
    our $POS_C       = ( $POS_A + $SIZE_A );
    our $POS_B       = ( $POS_C + $SIZE_C );
    our $POS_Bx      = $POS_C;
    our $POS_Ax      = $POS_A;
    our $MAXARG_Bx   = ( ( 1 << $SIZE_Bx ) - 1 );
    our $MAXfARG_sBx = ( $MAXARG_Bx >> 1 );
    our $MAXARG_Ax   = ( ( 1 << $SIZE_Ax ) - 1 );
    our $MAXARG_A    = ( ( 1 << $SIZE_A ) - 1 );
    our $MAXARG_B    = ( ( 1 << $SIZE_B ) - 1 );
    our $MAXARG_C    = ( ( 1 << $SIZE_C ) - 1 );
    our $BITRK       = ( 1 << ( $SIZE_B - 1 ) );
    our $MAXINDEXRK  = ( $BITRK - 1 );

    sub RKASK { my $x = shift; $x | $BITRK; }
    sub ISK { my $x = shift; ( $x & $BITRK ) != 0; }
    sub INDEXK { my $r = shift; $r & ~$BITRK; }
    sub MYK    { my $x = shift; -1 - $x; }

    sub MASK1 {
        my ( $size, $pos ) = @_;
        ( ( ~( ( ~(0) ) << $size ) ) << $pos );
    }

    sub MASK0 {
        my ( $size, $pos ) = @_;
        ~MASK1( $size, $pos );
    }
    method GET_OPCODE { }
    method SET_OPCODE { }
    method GETARG { }
    method SETARG { }
    method GETARG_A { }
    method GETARG_B { }
    method GETARG_C { }
    method GETARG_Bx { }
    method GETARG_Ax { }
    method GETARG_sBx { }

    sub CreateABC {}
    sub CreateABx {}
    sub CreateAx {}
}

1;
