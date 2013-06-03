# lib/VM/ExecuteEnvironment.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::ExecuteEnvironment {

    use VM::StkId;
    use VM::Instruction;
    use VM::State;
    use aliased 'VM::TagMethod::TMS';

    has [ 'k', 'base' ] => (
        is  => 'rw',
        isa => 'VM::StkId'
    );

    has 'i' => (
        is  => 'rw',
        isa => 'VM::Instruction',
    );

    method clone {
        my $new_env = new VM::ExecuteEnvironment;
        if(defined($self->k)){
            $new_env->k($self->k->clone);
        }
        if(defined($self->base)){
            $new_env->base($self->base->clone);
        }
        if(defined($self->i)){
            $new_env->i($self->i->clone);
        }
        return $new_env;
    }
    method RA { return $self->base + $self->i->GETARG_A(); }
    method RB { return $self->base + $self->i->GETARG_B(); }

    method RK (Int $x) {
        return Instruction->ISK($x)
          ? $self->k + Instruction->INDEXK($x)
          : $self->base + $x;
    }

    method RKB {
        return $self->RK( $self->i->GETARG_B() );
    }

    method RKC {
        return $self->RK( $self->i->GETARG_C );
    }

    method arith_op (VM::State $lua, Int $tm, CodeRef $op) {  #$tm=>VM::TagMethod::TMS

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
}

1;
