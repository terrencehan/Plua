# t/04-vm-instruction.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;

#use warnings;

use lib '../lib';

#use Test::More tests => 15;
use Test::More 'no_plan';

use_ok 'VM::Instruction';

my $i = VM::Instruction->new( value => 0b000000000_000000000_00000000_000111 );
isa_ok $i, 'VM::Instruction';

is $VM::Instruction::SIZE_C,   9;
is $VM::Instruction::SIZE_B,   9;
is $VM::Instruction::SIZE_Bx,  18;
is $VM::Instruction::SIZE_A,   8;
is $VM::Instruction::SIZE_Ax,  26;
is $VM::Instruction::SIZE_OP,  6;
is $VM::Instruction::POS_OP,   0;
is $VM::Instruction::POS_A,    6;
is $VM::Instruction::POS_C,    14;
is $VM::Instruction::POS_B,    23;
is $VM::Instruction::POS_Bx,   14;
is $VM::Instruction::POS_Ax,   6;
is $VM::Instruction::MAXARG_A, 2**8 - 1;
is $VM::Instruction::BITRK,    0b100000000;

is( VM::Instruction->ISK(0b100000001),    1 );
is( VM::Instruction->ISK(0b000000001),    '' );
is( VM::Instruction->INDEXK(0b100000101), 5 );
is( VM::Instruction->RKASK(5),  0b100000101);
is unpack( "B32", pack( "N", VM::Instruction->MASK1( 3, 0 ) ) ),
  "00000000000000000000000000000111";
is unpack( "B32", pack( "N", VM::Instruction->MASK0( 2, 3 ) ) ),
  "11111111111111111111111111100111";

is $i->GET_OPCODE, 0b111;
$i->SET_OPCODE(0b010);
is $i->GET_OPCODE, 0b010;
$i->SET_OPCODE(0b111); #reset
