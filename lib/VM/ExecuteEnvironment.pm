# lib/VM/ExecuteEnvironment.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::ExecuteEnvironment;

use lib '../';
use plua;

use VM::StkId;
use VM::Instruction;
use VM::State;
use aliased 'VM::TagMethod::TMS';

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'k',    'base',    #VM::StkId
        'i',               #VM::Instruction
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

sub clone {
    my ($self) = @_;
    my $new_env = new VM::ExecuteEnvironment;
    if ( defined( $self->k ) ) {
        $new_env->k( $self->k->clone );
    }
    if ( defined( $self->base ) ) {
        $new_env->base( $self->base->clone );
    }
    if ( defined( $self->i ) ) {
        $new_env->i( $self->i->clone );
    }
    return $new_env;
}

sub RA {
    my ($self) = @_;
    return $self->base + $self->i->GETARG_A();
}

sub RB {
    my ($self) = @_;
    return $self->base + $self->i->GETARG_B();
}

sub RK {
    my (
        $self, $x    #Int
    ) = @_;
    return VM::Instruction->ISK($x)
      ? $self->k + VM::Instruction->INDEXK($x)
      : $self->base + $x;
}

sub RKB {
    my ($self) = @_;
    return $self->RK( $self->i->GETARG_B() );
}

sub RKC {
    my ($self) = @_;
    return $self->RK( $self->i->GETARG_C );
}

sub arith_op {    #$tm=>VM::TagMethod::TMS

    my (
        $self,
        $lua,     #VM::State
        $tm,      #Int =>VM::TagMethod::TMS
        $op,      #CodeRef
    ) = @_;
    my $lhs = $self->RKB->value;
    my $rhs = $self->RKC->value;
    if (   ( ref($lhs) eq 'VM::Object::Number' )
        && ( ref($rhs) eq 'VM::Object::Number' ) )
    {
        my $ra = $self->RA;
        my $res = $op->( $lhs->value, $rhs->value );
        $ra->value = new VM::Object::Number( value => $res );
    }
    else {
        $lua->v_arith( $self->RA, $self->RKB, $self->RKC, $tm );
    }

}

1;
