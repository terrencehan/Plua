# lib/VM/State.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;
use v5.10;

class VM::State extends VM::Object {
    use lib '../';

    #-BUILD (g => VM::GlobalState = undef)
    use VM::Object::Table;
    use VM::Object::Upvalue;
    use VM::GlobalState;
    use VM::CallInfo;
    use VM::Object::Nil;
    use aliased 'VM::Util';
    use aliased 'VM::Common::LuaType';
    use aliased 'VM::Common::LuaOp';
    use aliased 'VM::Common::LuaDef';
    use aliased 'VM::Common::ThreadStatus';

    method BUILD {
        $self->type( LuaType->LUA_TTHREAD );
        $self->is_thread(1);
        $self->num_none_yieldable(1);
        $self->num_perl_calls(0);
        $self->hook_mask(0);
        $self->err_func(0);
        $self->base_hook_count(0);
        $self->reset_hook_count();

        if ( !defined( $self->g ) ) {
            $self->g( new VM::GlobalState( state => $self ) );
        }

        $self->init_stack();
    }

    sub o_arith {
        my (
            $class,
            $op,    # LuaOp
            $v1,    # Num
            $v2,    # Num
        ) = @_;
        given ($op) {
            when ( LuaOp->LUA_OPADD . '' ) { return $v1 + $v2; }
            when ( LuaOp->LUA_OPSUB . '' ) { return $v1 - $v2; }
            when ( LuaOp->LUA_OPMUL . '' ) { return $v1 * $v2; }
            when ( LuaOp->LUA_OPDIV . '' ) { return $v1 / $v2; }
            when ( LuaOp->LUA_OPMOD . '' ) { return $v1 % $v2; }
            when ( LuaOp->LUA_OPPOW . '' ) { return $v1**$v2; }
            when ( LuaOp->LUA_OPUNM . '' ) { return -$v1; }
            default                        { die; }
        }
    }

    sub o_str2decimal {    #return Bool
        my (
            $class,
            $s,            # Str
            $result,       # ScalarRef[Num]
        ) = @_;

        $$result = 0.0;

        if ( $s =~ /[nN]/ ) {
            return 0;      #false; reject `inf' and `nan'
        }

        my $pos = 0;
        if ( $s =~ /[xX]/ ) {
            $$result = Util->strX2number( $s, \$pos );
        }
        else {
            $$result = Util->str2number( $s, \$pos );
        }

        if ( $pos == 0 ) {
            return 0;      #false; nothing recognized
        }

        my @s_arr = split //, $s;
        while ( $pos < length($s) && $s_arr[$pos] =~ /\s/ ) {
            $pos++;
        }

        return $pos == length($s);    #TRUE if no trailing characters
    }

    has 'top' => (
        is  => 'rw',
        isa => 'VM::StkId',
    );

    has [ 'ci', 'base_ci' ] => (
        is  => 'rw',
        isa => 'VM::CallInfo',
    );

    has 'g' => (
        is  => 'rw',
        isa => 'VM::GlobalState',
    );

    has [
        'num_none_yieldable', 'num_perl_calls',
        'err_func',           'base_hook_count',
        'hook_count',         'hook_mask'
      ] => (
        is  => 'rw',
        isa => 'Int',
      );

    has 'allow_hook' => (
        is      => 'rw',
        isa     => 'Bool',
        default => 1,
    );

    has 'hook' => (
        is      => 'rw',
        isa     => 'CodeRef|Undef',
        default => undef,
    );

    has 'open_upval' => (    #linkedlist
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object::Upvalue]',
        default => sub { [] },
    );

    has 'instruction_history' => (    #queue
        is      => 'rw',
        isa     => 'ArrayRef[VM::Instruction]',
        default => sub { [] },
    );

    has 'api' => (
        is  => 'rw',
        isa => 'VM::LuaAPI',
    );

    has 'status' => (
        is      => 'rw',
        isa     => 'Int',
        default => ThreadStatus->LUA_OK,
    );

    has 'state_stack' => (
        is  => 'rw',
        isa => 'ArrayRef[VM::Object]',
    );

    method reset_hook_count {
        $self->hook_count( $self->base_hook_count );
    }

    method init_registry {
        $self->g->registy->set_int();
    }

    method incr_top {
        $self->top->index( $self->top->index + 1 );
    }

    method api_incr_top {
        $self->top->index( $self->top->index + 1 );
        Util->api_check( $self->top->index <= $self->ci->top->index,
            'stack overflow' );
    }

    method init_stack {
        $self->state_stack( [] );
        $self->top( new VM::StkId( list => $self->state_stack, index => 0 ) );
        $self->base_ci( new VM::CallInfo );
        $self->base_ci->previous(undef);
        $self->base_ci->next(undef);
        $self->base_ci->func( $self->top );
        $self->top->value_inc( new VM::Object::Nil )
          ;                   #`function' entry for this `ci'
        $self->base_ci->top( $self->top + LuaDef->LUA_MINSTACK );
        $self->ci( $self->base_ci );
    }

}

1;
