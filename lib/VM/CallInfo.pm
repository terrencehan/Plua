# lib/VM/CallInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::CallInfo;

use lib '../';
use plua;
use VM::StkId;
use VM::CallStatus;
use VM::Pointer;
use aliased 'VM::Util';
use VM::Common::ThreadStatus;

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'func', 'top', 'base', 'extra',    #VM::StkId
        'previous', 'next',                          #VM::CallInfo
        'num_results', 'context', 'old_err_func',    #Int
        'call_status',                               #VM::CallStatus
        'status',                                    #Int
        'continue_func',                             #CodeRef
        'saved_pc',                                  #VM::Pointer
        'old_allow_hook',                            #Bool
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

sub is_lua {
    my $self = shift;
    my $status = defined( $self->call_status ) ? $self->call_status : 0;
    return ( $status & VM::CallStatus->CIST_LUA ) != 0;
}

sub current_lua_func {                               #get
    my $self = shift;
    if ( $self->is_lua ) {
        return $self->func->value;
    }
    return undef;
}

sub current_line {                                   #get
    my $self = shift;
    return $self->func->value->proto->get_func_line( $self->current_pc );
}

sub current_pc {                                     #get
    my $self = shift;
    Util->assert( $self->is_lua );
    return $self->saved_pc->index - 1;
}

1;
