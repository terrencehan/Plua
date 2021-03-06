# lib/VM/Instruction.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

package VM::Instruction;

#--BUILD(value => Int)

sub new {
    my $class = shift;
    my $self  = { @_, };
    bless $self, $class;
}

sub value {
    my ( $self, $val ) = @_;
    if ( defined($val) ) {
        return $self->{value} = $val;
    }
    else {
        return $self->{value};
    }
}

sub clone {
    my ($self) = @_;
    return new VM::Instruction( value => $self->value );
}

#class variable
our $SIZE_C  = 9;
our $SIZE_B  = 9;
our $SIZE_Bx = ( $SIZE_C + $SIZE_B );
our $SIZE_A  = 8;
our $SIZE_Ax = ( $SIZE_C + $SIZE_B + $SIZE_A );
our $SIZE_OP = 6;

our $POS_OP = 0;
our $POS_A  = ( $POS_OP + $SIZE_OP );
our $POS_C  = ( $POS_A + $SIZE_A );
our $POS_B  = ( $POS_C + $SIZE_C );
our $POS_Bx = $POS_C;
our $POS_Ax = $POS_A;

our $MAXARG_Bx   = ( ( 1 << $SIZE_Bx ) - 1 );
our $MAXfARG_sBx = ( $MAXARG_Bx >> 1 );
our $MAXARG_Ax   = ( ( 1 << $SIZE_Ax ) - 1 );
our $MAXARG_A    = ( ( 1 << $SIZE_A ) - 1 );
our $MAXARG_B    = ( ( 1 << $SIZE_B ) - 1 );
our $MAXARG_C    = ( ( 1 << $SIZE_C ) - 1 );

# this bit 1 means constant (0 means register)
our $BITRK = ( 1 << ( $SIZE_B - 1 ) );

our $MAXINDEXRK = ( $BITRK - 1 );

# code a constant index as a RK value
sub RKASK {
    if ( $_[0] eq "VM::Instruction" ) {
        shift;
    }
    my $x = shift;
    $x | $BITRK;
}

# test whether value is a constant
sub ISK {
    if ( $_[0] eq "VM::Instruction" ) {
        shift;
    }
    my $x = shift;
    ( $x & $BITRK ) != 0;
}

# gets the index of the constant
sub INDEXK {
    if ( $_[0] eq "VM::Instruction" ) {
        shift;
    }
    my $r = shift;
    $r & ~$BITRK;
}

sub MYK {
    if ( $_[0] eq "VM::Instruction" ) {
        shift;
    }
    my $x = shift;
    -1 - $x;
}

# creates a mask with `n' 1 bits at position `p'
sub MASK1 {
    if ( $_[0] eq "VM::Instruction" ) {
        shift;
    }
    my ( $n, $p ) = @_;
    ( ( ~( ( ~(0) ) << $n ) ) << $p );
}

# creates a mask with `n' 0 bits at position `p'
sub MASK0 {
    if ( $_[0] eq "VM::Instruction" ) {
        shift;
    }
    my ( $n, $p ) = @_;
    ~MASK1( $n, $p );
}

sub GET_OPCODE {
    my ($self) = @_;
    ( $self->value >> $POS_OP ) & MASK1( $SIZE_OP, 0 );
}

sub SET_OPCODE {
    my ( $self, $op ) = @_;
    $self->value( ( $self->value & MASK0( $SIZE_OP, $POS_OP ) ) |
          ( $op << $POS_OP & MASK1( $SIZE_OP, $POS_OP ) ) );
    $self;
}

sub GETARG {
    my ( $self, $pos, $size ) = @_;
    ( $self->value >> $pos ) & MASK1( $size, 0 );
}

sub SETARG {
    my ( $self, $value, $pos, $size ) = @_;
    $self->value( ( $self->value & MASK0( $size, $pos ) ) |
          ( $value << $pos & MASK1( $size, $pos ) ) );
    $self;
}

sub GETARG_A {
    my ($self) = @_;
    $self->GETARG( $POS_A, $SIZE_A );
}

sub GETARG_B {
    my ($self) = @_;
    $self->GETARG( $POS_B, $SIZE_B );
}

sub GETARG_C {
    my ($self) = @_;
    $self->GETARG( $POS_C, $SIZE_C );
}

sub GETARG_Bx {
    my ($self) = @_;
    $self->GETARG( $POS_Bx, $SIZE_Bx );
}

sub GETARG_Ax {
    my ($self) = @_;
    $self->GETARG( $POS_Ax, $SIZE_Ax );
}

sub GETARG_sBx {
    my ($self) = @_;
    $self->GETARG_Bx - $MAXfARG_sBx;
}

sub SETARG_A {
    my ( $self, $value ) = @_;
    $self->SETARG( $value, $POS_A, $SIZE_A );
}

sub SETARG_B {
    my ( $self, $value ) = @_;
    $self->SETARG( $value, $POS_B, $SIZE_B );
}

sub SETARG_C {
    my ( $self, $value ) = @_;
    $self->SETARG( $value, $POS_C, $SIZE_C );
}

sub SETARG_Bx {
    my ( $self, $value ) = @_;
    $self->SETARG( $value, $POS_Bx, $SIZE_Bx );
}

sub SETARG_Ax {
    my ( $self, $value ) = @_;
    $self->SETARG( $value, $POS_Ax, $SIZE_Ax );
}

sub SETARG_sBx {
    my ( $self, $value ) = @_;
    $self->SET_Bx( $value + $MAXfARG_sBx );
}

sub CreateABC {
    shift;
    my ( $op, $a, $b, $c ) = @_;
    VM::Instruction->new(
        value => ( $op << $POS_OP ) | ( $a << $POS_A ) | ( $b << $POS_B ) |
          ( $c << $POS_C ) );
}

sub CreateABx {
    shift;
    my ( $op, $a, $bc ) = @_;
    VM::Instruction->new(
        value => ( $op << $POS_OP ) | ( $a << $POS_A ) | ( $bc << $POS_Bx ) );
}

sub CreateAx {
    my ( $op, $a ) = @_;
    VM::Instruction->new( ( $op << $POS_OP ) | ( $a << $POS_Ax ) );
}

1;
