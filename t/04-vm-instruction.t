# t/04-vm-instruction.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;

#use warnings;

use lib '../lib';

#use Test::More tests => 15;
use Test::More 'no_plan';

use_ok 'VM::Instruction';

my $i = VM::Instruction->new( value => 0b000100100_100000001_11000000_000111 );
isa_ok $i, 'VM::Instruction';

is $VM::Instruction::SIZE_C,  9;
is $VM::Instruction::SIZE_B,  9;
is $VM::Instruction::SIZE_Bx, 18;
is $VM::Instruction::SIZE_A,  8;

#is $VM::Instruction::SIZE_Ax,  26;
is $VM::Instruction::SIZE_OP, 6;
is $VM::Instruction::POS_OP,  0;
is $VM::Instruction::POS_A,   6;
is $VM::Instruction::POS_C,   14;
is $VM::Instruction::POS_B,   23;
is $VM::Instruction::POS_Bx,  14;

#is $VM::Instruction::POS_Ax,   6;
is $VM::Instruction::MAXARG_A, 2**8 - 1;
is $VM::Instruction::BITRK,    0b100000000;

sub to_binary_string {
    unpack( "B32", pack( "N", shift ) );
}

is( VM::Instruction->ISK(0b100000001),    1 );
is( VM::Instruction->ISK(0b000000001),    '' );
is( VM::Instruction->INDEXK(0b100000101), 5 );
is( VM::Instruction->RKASK(5),            0b100000101 );
is to_binary_string( VM::Instruction->MASK1( 3, 0 ) ),
  "00000000000000000000000000000111";
is to_binary_string( VM::Instruction->MASK0( 2, 3 ) ),
  "11111111111111111111111111100111";

is $i->GET_OPCODE, 0b111;
$i->SET_OPCODE(0b010);
is $i->GET_OPCODE, 0b010;
$i->SET_OPCODE(0b111);    #reset

#my $i = VM::Instruction->new( value => 0b000100100_100000001_11000000_000111 );
is $i->GETARG_A,  0b11000000;
is $i->GETARG_B,  0b000100100;
is $i->GETARG_C,  0b100000001;
is $i->GETARG_Bx, 0b000100100_100000001;
is(
    VM::Instruction->CreateABC( 0b111, 0b11000000, 0b000100100, 0b100000001 )
      ->value,
    $i->value
);

is(
    VM::Instruction->CreateABx( 0b111, 0b11000000, 0b000100100_100000001 )
      ->value,
    $i->value
);

$i->SETARG_A(0b11001100);
is $i->GETARG_A,  0b11001100;
$i->SETARG_B(0b010100100);
is $i->GETARG_B,  0b010100100;
$i->SETARG_C(0b101000001);
is $i->GETARG_C,  0b101000001;
$i->SETARG_Bx(0b000100101_101000001);
is $i->GETARG_Bx, 0b000100101_101000001;
