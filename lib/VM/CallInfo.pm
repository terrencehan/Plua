# lib/VM/CallInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::CallInfo {

    use VM::StkId;
    use VM::CallStatus;
    use VM::Pointer;
    use aliased 'VM::Util';
    use VM::Common::ThreadStatus;

    has [ 'func', 'top', 'base', 'extra' ] => (
        is  => 'rw',
        isa => 'VM::StkId',
    );

    has [ 'previous', 'next' ] => (
        is  => 'rw',
        isa => 'VM::CallInfo|Undef',
    );

    has [ 'num_results', 'context', 'old_err_func' ] => (
        is  => 'rw',
        isa => 'Int',
    );

    has 'call_status' => (
        is => 'rw',

        #isa => 'VM::CallStatus',
        isa => 'Int',
    );

    has 'status' => (
        is => 'rw',

        #isa => 'VM::Common::ThreadStatus',
        isa => 'Int',
    );

    has 'continue_func' => (
        is  => 'rw',
        isa => 'CodeRef',
    );

    has 'saved_pc' => (
        is  => 'rw',
        isa => 'VM::Pointer',
    );

    has 'old_allow_hook' => (
        is  => 'rw',
        isa => 'Bool',
    );

    method is_lua {
        return ( $self->call_status & VM::CallStatus->CIST_LUA ) != 0;
    }

    method current_lua_func {    #get
        if ( $self->is_lua ) {
            return $self->func->value;
        }
        return undef;
    }

    method current_line {        #get
        return $self->fun->value->proto->get_func_line( $self->current_pc );
    }

    method current_pc {          #get
        Uiil->assert( $self->is_lua );
        return $self->saved_pc->index - 1;
    }

}

1;
