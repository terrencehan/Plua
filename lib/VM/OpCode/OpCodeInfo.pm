# lib/VM/OpCode/OpCodeInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::OpCode::OpCodeInfo;
use strict;
use warnings;

#--BUILD()
use lib '../../';
use aliased 'VM::OpCode::OpArgMask';
use aliased 'VM::OpCode::OpMode';
use aliased 'VM::OpCode';
use VM::OpCode::OpCodeMode;

sub new {
    my $class = shift;
    bless {};
}

sub get_mode {
    my ( $class, $op ) = @_;
    $class->info->{$op};
}

sub mm {
    my ( $t, $a, $b, $c, $op ) = @_;
    VM::OpCode::OpCodeMode->new(
        TMode  => $t,
        AMode  => $a,
        BMode  => $b,
        CMode  => $c,
        OpMode => $op,
    );
}

my $info = {};
$info->{ OpCode->OP_MOVE } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_LOADK } =
  mm( 0, 1, OpArgMask->OpArgN, OpArgMask->OpArgN, OpMode->iABx );
$info->{ OpCode->OP_LOADBOOL } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgU, OpMode->iABC );
$info->{ OpCode->OP_LOADNIL } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_GETUPVAL } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_GETTABLE } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_SETUPVAL } =
  mm( 0, 0, OpArgMask->OpArgU, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_SETTABLE } =
  mm( 0, 0, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_NEWTABLE } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgU, OpMode->iABC );
$info->{ OpCode->OP_SELF } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_ADD } =
  mm( 0, 1, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_SUB } =
  mm( 0, 1, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_MUL } =
  mm( 0, 1, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_DIV } =
  mm( 0, 1, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_MOD } =
  mm( 0, 1, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_POW } =
  mm( 0, 1, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_UNM } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_NOT } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_LEN } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_CONCAT } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgR, OpMode->iABC );
$info->{ OpCode->OP_JMP } =
  mm( 0, 0, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iAsBx );
$info->{ OpCode->OP_EQ } =
  mm( 1, 0, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_LT } =
  mm( 1, 0, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_LE } =
  mm( 1, 0, OpArgMask->OpArgK, OpArgMask->OpArgK, OpMode->iABC );
$info->{ OpCode->OP_TEST } =
  mm( 1, 0, OpArgMask->OpArgN, OpArgMask->OpArgU, OpMode->iABC );
$info->{ OpCode->OP_TESTSET } =
  mm( 1, 1, OpArgMask->OpArgR, OpArgMask->OpArgU, OpMode->iABC );
$info->{ OpCode->OP_CALL } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgU, OpMode->iABC );
$info->{ OpCode->OP_TAILCALL } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgU, OpMode->iABC );
$info->{ OpCode->OP_RETURN } =
  mm( 0, 0, OpArgMask->OpArgU, OpArgMask->OpArgN, OpMode->iABC );
$info->{ OpCode->OP_FORLOOP } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iAsBx );
$info->{ OpCode->OP_FORPREP } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iAsBx );
$info->{ OpCode->OP_TFORLOOP } =
  mm( 0, 1, OpArgMask->OpArgR, OpArgMask->OpArgN, OpMode->iAsBx );
$info->{ OpCode->OP_SETLIST } =
  mm( 0, 0, OpArgMask->OpArgU, OpArgMask->OpArgU, OpMode->iABC );
$info->{ OpCode->OP_CLOSURE } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgN, OpMode->iABx );
$info->{ OpCode->OP_VARARG } =
  mm( 0, 1, OpArgMask->OpArgU, OpArgMask->OpArgN, OpMode->iABC );

sub info {    #get
    my ( $self, $val ) = @_;
    return $info;
}
1;
