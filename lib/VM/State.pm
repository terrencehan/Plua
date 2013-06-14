# lib/VM/State.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::State;

use v5.10;

use strict;
use warnings;

use lib '../';
use plua;
use VM::Object::Table;
use VM::Object::Upvalue;
use VM::GlobalState;
use VM::CallInfo;
use VM::LoadInfo;
use VM::Undump;
use VM::File;
use VM::CallS;
use VM::ExecuteEnvironment;
use VM::LoadParameter;
use VM::Object::Nil;
use VM::Object::Proto;
use VM::Object::LClosure;
use VM::Object::PClosure;
use Lib::Base;
use aliased 'Common::NameFuncPair';
use aliased 'VM::Util';
use aliased 'VM::OpCode';
use aliased 'VM::CallStatus';
use aliased 'VM::Common::LuaType';
use aliased 'VM::Common::LuaOp';
use aliased 'VM::Common::LuaDef';
use aliased 'VM::Common::LuaConf';
use aliased 'VM::Common::LuaLimits';
use aliased 'VM::Common::ThreadStatus';
use aliased 'VM::TagMethod::TMS';

use parent qw/VM::Object/;

#-BUILD (g => VM::GlobalState = undef)

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'top',    #VM::StkId
        'ci', 'base_ci',    #VM::CallInfo
        'g',                #VM::GlobalState

        'num_none_yieldable', 'num_perl_calls', 'err_func', 'base_hook_count',
        'hook_count',         'hook_mask',      #Int
        'allow_hook',             #Bool
        'hook',                   #CodeRef
        'open_upval',             #ArrayRef[VM::Object::Upvalue|Undef]
        'instruction_history',    #ArrayRef[VM::Instruction]
        'api',                    #VM::LuaAPI
        'state_stack',            # ArrayRef[VM::Object]
    );

    attr( $class, ThreadStatus->LUA_OK, 'status' );    #Int
}

sub new {
    my ( $class, @args ) = @_;

    my $self = bless {@args}, $class;

    $self->api($self);
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
    return $self;
}

sub o_arith {
    my (
        $self,
        $op,    #Int #$op=>LuaOp
        $v1,    #Num
        $v2,    #Num
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

sub o_str2decimal {
    my (
        $self,
        $s,         #Str
        $result,    #ScalarRef[Num]
    ) = @_;
    $$result = 0.0;

    if ( $s =~ /[nN]/ ) {
        return 0;    #false; reject `inf' and `nan'
    }

    my $pos = 0;
    if ( $s =~ /[xX]/ ) {
        $$result = Util->strX2number( $s, \$pos );
    }
    else {
        $$result = Util->str2number( $s, \$pos );
    }

    if ( $pos == 0 ) {
        return 0;    #false; nothing recognized
    }

    my @s_arr = split //, $s;
    while ( $pos < length($s) && $s_arr[$pos] =~ /\s/ ) {
        $pos++;
    }

    return $pos == length($s);    #TRUE if no trailing characters
}

sub reset_hook_count {
    my ($self) = @_;
    $self->hook_count( $self->base_hook_count );
}

sub init_registry {
    my ($self) = @_;
    $self->g->registy->set_int( LuaDef->LUA_RIDX_MAINTHREAD, $self );
    $self->g->registy->set_int( LuaDef->LUA_RIDX_GLOBALS,
        new VM::Object::Table );
}

sub incr_top {
    my ($self) = @_;
    $self->top->index( $self->top->index + 1 );
}

sub restore_stack {
    my (
        $self,
        $index,    #Int
    ) = @_;
    return new VM::StkId( list => $self->state_stack, index => $index );
}

sub api_incr_top {
    my ($self) = @_;
    $self->top->index( $self->top->index + 1 );
    Util->api_check( $self->top->index <= $self->ci->top->index,
        'stack overflow' );
}

sub init_stack {
    my ($self) = @_;
    $self->state_stack( [] );
    $self->top( new VM::StkId( list => $self->state_stack, index => 0 ) );
    $self->base_ci( new VM::CallInfo );
    $self->base_ci->previous(undef);
    $self->base_ci->next(undef);
    $self->base_ci->func( $self->top->clone );
    $self->top->value_inc( new VM::Object::Nil )
      ;    #`function' entry for this `ci'
    $self->base_ci->top( $self->top + LuaDef->LUA_MINSTACK );
    $self->ci( $self->base_ci );
}

sub dump_stack {

    #TODO for debug purpose
}

sub dump_stack_to_string {
    my ($self) = @_;
    die "#TODO";
}

#API part:
sub new_thread {    #LuaAPI
    my ($self) = @_;
    my $new_lua = new VM::State( g => $self->g );
    $self->top->value($new_lua);
    $self->api_incr_top();

    $new_lua->hook_mask( $self->hook_mask );
    $new_lua->base_hook_count( $self->base_hook_count );
    $new_lua->hook( $self->hook );
    $new_lua->reset_hook_count();

    return $new_lua;
}

sub check_mode {
    my (
        $self,
        $given,       #Str
        $expected,    #Str
    ) = @_;
    if ( defined($given) && $given ne $expected ) {
        $self->o_push_string(
            "attempt to load a $expected chunk (mode is '{$given}'");
        $self->d_throw( ThreadStatus->LUA_ERRSYNTAX );
    }
}

sub f_load {
    my ( $self, $ud, ) = @_;
    my $param = $ud;
    my $proto;
    my $c = $param->load_info->peek_byte;

    #if ( $c == LuaConf->LUA_SIGNATURE ) {
    if (1) {    #TODO
        $self->check_mode( $param->mode, "binary" );    #TODO
        $proto =
          VM::Undump->load_binary( $self, $param->load_info, $param->name );
    }
    else {
        $self->check_mode( $param->mode, "text" );      #TODO
        $proto =
          Parser::Parser->parse( $self, $param->load_info, $param->name );
    }
    my $cl = new VM::Object::LClosure( proto => $proto );
    Util->assert( scalar @{ $cl->upvals } == scalar @{ $cl->proto->upvalues } );

    ## initialize upvalues
    for ( my $i = 0 ; $i < scalar @{ $proto->upvalues } ; ++$i ) {
        $cl->upvals->[$i] = new VM::Object::Upvalue;
    }

    $self->top->value($cl);
    $self->incr_top();
}

sub load {    #LuaAPI
    my (
        $self,
        $load_info,    #VM::LoadInfo
        $name,         #Str
        $mode,         #Str
    ) = @_;
    my $param = new VM::LoadParameter(
        load_info => $load_info,
        name      => $name,
        mode      => $mode,
    );

    my $status = $self->d_p_call( sub { $self->f_load(@_) },
        $param, $self->top, $self->err_func );

    if ( $status == ThreadStatus->LUA_OK ) {
        my $cl = Util->as( ( $self->top - 1 )->value, 'VM::Object::LClosure' );
        if ( defined($cl) && @{ $cl->upvals } == 1 ) {
            $cl->upvals->[0]->v->value(
                $self->g->registy->get_int( LuaDef->LUA_RIDX_GLOBALS ) );
        }
    }

    return $status;
}

sub dump {    #LuaAPI

    my ($self) = @_;
    die "#TODO";
}

sub get_context {    #LuaAPI

    my ($self) = @_;
    die "#TODO";

}

sub call {           #LuaAPI
    my (
        $self,
        $num_args,       #Int
        $num_results,    #Int
    ) = @_;
    $self->api->call_k( $num_args, $num_results, 0, undef );
}

sub call_k {             #LuaAPI
    my (
        $self,
        $num_args,         #Int
        $num_results,      #Int
        $context,          #Int
        $continue_func,    #CodeRef
    ) = @_;
    Util->api_check(
        !defined($continue_func) || !$self->ci->is_lua,
        "cannot use continuations inside hooks"
    );
    Util->api_check_num_elems( $self, $num_args + 1 );
    Util->api_check(
        $self->status == ThreadStatus->LUA_OK,
        'cannot do calls on non-normal thread'
    );
    $self->check_results( $num_args, $num_results );

    my $func = $self->top - ( $num_args + 1 );

    # need to prepare continuation?
    if ( defined($continue_func) && $self->num_none_yieldable == 0 ) {
        $self->ci->continue_func = $continue_func;
        $self->ci->context       = $context;
        $self->d_call( $func, $num_results, 1 );
    }

    # no continuation or no yieldable
    else {
        $self->d_call( $func, $num_results, 0 );
    }

    $self->adjust_results($num_results);
}

sub f_call {
    my ( $self, $ud, ) = @_;
    my $c = $ud;    #VM::CallS
    $self->d_call( $c->func, $c->num_results, 0 );
}

sub check_results {
    my (
        $self,
        $num_args,       #Int
        $num_results,    #Int
    ) = @_;
    Util->api_check(
        $num_results == LuaDef->LUA_MULTRET
          || $self->ci->top->index - $self->top->index >=
          $num_results - $num_args,
        "results from function overflow current stack size"
    );
}

sub adjust_results {
    my (
        $self,
        $num_results,    #Int
    ) = @_;
    if (   $num_results == LuaDef->LUA_MULTRET
        && $self->ci->top->index < $self->top->index )
    {
        $self->ci->top( $self->top->clone );
    }
}

sub p_call {             #LuaAPI
    my (
        $self,
        $num_args,       #Int
        $num_results,    #Int
        $err_func,       #Int
    ) = @_;
    return $self->api->p_call_k( $num_args, $num_results, $err_func, 0, undef );
}

sub p_call_k {           #LuaAPI
    my (
        $self,
        $num_args,         #Int
        $num_results,      #Int
        $err_func,         #Int
        $context,          #Int
        $continue_func,    #CodeRef
    ) = @_;
    Util->api_check(
        !defined($continue_func) || !$self->ci->is_lua,
        "cannot use continuations inside hooks"
    );
    Util->api_check_num_elems( $self, $num_args + 1 );
    Util->api_check(
        $self->status == ThreadStatus->LUA_OK,
        "cannot do calls on non-normal thread"
    );
    $self->check_results( $num_args, $num_results );

    my $func;    #Int
    if ( $err_func == 0 ) {
        $func = 0;
    }
    else {
        my $addr;    #VM::StkId
        if ( !$self->index2addr( $err_func, \$addr ) ) {
            Util->invalid_index();
        }
        $func = $addr->index;
    }

    my $status;      #VM::Common::ThreadStatus
    my $c = new VM::CallS;
    $c->func( $self->top - ( $num_args + 1 ) );
    if ( !defined($continue_func) || $self->num_none_yieldable > 0 )
    {                #no continuatoin or no yieldable?
        $c->num_results($num_results);
        $status =
          $self->d_p_call( sub { $self->f_call(@_); }, $c, $c->func, $func );
    }
    else {
        my $ci = $self->ci;
        $ci->continue_func($continue_func);
        $ci->context($context);
        $ci->extra( $c->func->clone );
        $ci->old_allow_hook( $self->allow_hook );
        $ci->old_err_func( $self->err_func );
        $self->err_func( $func->clone );
        $ci->call_status( $ci->call_status | CallStatus->CIST_YPCALL );
        $self->d_call( $c->func, $num_results, 1 );
        $ci->call_status( $ci->call_status & ( ~CallStatus->CIST_YPCALL ) );
        $self->err_func( $ci->old_err_func );
        $status = ThreadStatus->LUA_OK;
    }
    $self->adjust_results($num_results);
    return $status;
}

sub finish_perl_call {
    my ($self) = @_;
    die "#TODO";
}

sub unroll {
    my ($self) = @_;
    die "#TODO";
}

sub resume_err {
    my ($self) = @_;
    die "#TODO";
}

sub find_p_call {
    my ($self) = @_;
    die "#TODO";
}

sub recover {
    my ($self) = @_;
    die "#TODO";
}

sub _resume {    #name conflict with API method
    my ($self) = @_;
    die "#TODO";
}

sub resume {     #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub yield {      #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub yield_k {    #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub abs_index {    #LuaAPI
    my (
        $self,
        $index,    #Int
    ) = @_;
    return ( $index > 0 || $index <= LuaDef->LUA_REGISTRYINDEX )
      ? $index
      : $self->top->index - $self->ci->func->index + $index;
}

sub get_top {      #LuaAPI
    my ($self) = @_;
    return $self->top->index - ( $self->ci->func->index + 1 );
}

sub set_top {      #LuaAPI
    my (
        $self,
        $index,    #Int
    ) = @_;
    my $func = $self->ci->func->clone;
    if ( $index >= 0 ) {
        while ( $self->top->index < ( $func->index + 1 ) + $index ) {
            $self->top->value_inc( new VM::Object::Nil );
        }
        $self->top( $func + 1 + $index );
    }
    else {
        Util->api_check(
            -( $index + 1 ) <= ( $self->top->index - ( $func->index + 1 ) ),
            'invalid new top' );
        $self->top( $self->top + $index + 1 );
    }
}

sub remove {    #LuaAPI
    my (
        $self,
        $index,    #Int
    ) = @_;
    my $addr1;     #VM::StkId
    if ( !$self->index2addr( $index, \$addr1 ) ) {
        Util->invalid_index;
    }
    my $addr2 = $addr1 + 1;
    while ( $addr2->index < $self->top->index ) {
        $addr1->value_inc( $addr2->value_inc );
    }
    $self->top->index( $self->top->index - 1 );
}

sub insert {       #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub move_to {
    my ($self) = @_;
    die "#TODO";
}

sub replace {      #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub copy {         #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub x_move {       #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub error {        #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub upvalue_index {    #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub get_upvalue {      #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub set_upvalue {      #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub create_table {     #LuaAPI
    my ($self) = @_;
    $self->top->value( new VM::Object::Table );
    $self->api_incr_top();
}

sub new_table {        #LuaAPI
    my ($self) = @_;
    $self->api->create_table( 0, 0 );
}

sub next {             #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub raw_get_i {        #LuaAPI
    my (
        $self,
        $index,        #Int
        $n,            #Int
    ) = @_;
    my $addr;          #VM::StkId
    if ( !$self->index2addr( $index, \$addr ) ) {
        Util->api_check( 0, "table expected" );
    }

    my $tbl = Util->as( $addr->value, 'VM::Object::Table' );
    Util->api_check( defined($tbl), "table expected" );
    $self->top->value( $tbl->get_int($n) );
    $self->api_incr_top;
}

sub debug_get_instruction_history {    #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub raw_get {                          #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub raw_set_i {                        #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub raw_set {                          #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

=item get_field
Pushes onto the stack the value t[k],  where t is the value at the 
given index. As in Lua,  this function may trigger a metamethod for 
the "index" event
=cut

sub get_field {                        #LuaAPI
    my (
        $self,
        $index,                        #Int
        $key,                          #Str
    ) = @_;
    my $addr;                          #VM::StkId
    if ( !$self->index2addr( $index, \$addr ) ) {
        Util->invalid_index;
    }
    $self->top->value( new VM::Object::String( value => $key ) );
    my $below = $self->top->clone;
    $self->api_incr_top;
    $self->v_get_table( $addr->value, $below->value, $below );

}

=item set_field
Does the equivalent to t[k] = v,  where t is the value at the given 
index and v is the value at the top of the stack.  This function pops 
the value from the stack. As in Lua, this function may trigger a 
metamethod for the "newindex" event
=cut

sub set_field {    #LuaAPI
    my (
        $self,
        $index,    #Int
        $key,      #Str
    ) = @_;
    my $addr;      #VM::StkId
    if ( !$self->index2addr( $index, \$addr ) ) {
        Util->invalid_index();
    }
    $self->top->value_inc( new VM::Object::String( value => $key ) );
    $self->v_set_table(
        $addr->value,
        ( $self->top - 1 )->value,
        $self->top - 2
    );
    $self->top( $self->top - 2 );
}

sub concat {    #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub api_type
{    #name conflict with attr "type"                            #LuaAPI
    my (
        $self,
        $index,    #Int
    ) = @_;
    my $addr;      #VM::StkId
    if ( !$self->index2addr( $index, \$addr ) ) {
        return LuaType->LUA_TNONE;
    }

    return $addr->value->type;
}

sub type_name {    #LuaAPI
    my (
        $self,
        $t,        #Int
    ) = @_;
    given ($t) {

        when ( LuaType->LUA_TNIL . '' )           { return "nil"; }
        when ( LuaType->LUA_TBOOLEAN . '' )       { return "boolean"; }
        when ( LuaType->LUA_TLIGHTUSERDATA . '' ) { return "userdata"; }
        when ( LuaType->LUA_TUINT64 . '' )        { return "userdata"; }
        when ( LuaType->LUA_TNUMBER . '' )        { return "number"; }
        when ( LuaType->LUA_TSTRING . '' )        { return "string"; }
        when ( LuaType->LUA_TTABLE . '' )         { return "table"; }
        when ( LuaType->LUA_TFUNCTION . '' )      { return "function"; }
        when ( LuaType->LUA_TUSERDATA . '' )      { return "userdata"; }
        when ( LuaType->LUA_TTHREAD . '' )        { return "thread"; }
        when ( LuaType->LUA_TPROTO . '' )         { return "proto"; }
        when ( LuaType->LUA_TUPVAL . '' )         { return "upval"; }
        default                                   { return "no value"; }
    }
}

sub obj_type_name {
    my (
        $self,
        $o,    #VM::Object
    ) = @_;
    return $self->type_name( $o->type );
}

sub o_push_string {
    my (
        $self,
        $s,    #Str
    ) = @_;
    $self->top->value( new VM::Object::String( value => $s ) );
    $self->incr_top;
}

sub api_is_nil {    #LuaAPI
    my (
        $self,
        $index,     #Int
    ) = @_;
    return $self->api->api_type($index) == LuaType->LUA_TNIL;
}

sub api_is_none {    #LuaAPI
    my (
        $self,
        $index,      #Int
    ) = @_;
    return $self->api->api_type($index) == LuaType->LUA_TNONE;
}

sub api_is_none_or_nil {    #LuaAPI
    my (
        $self,
        $index,             #Int
    ) = @_;
    my $t = $self->api->api_type($index);
    return $t == LuaType->LUA_TNONE || $t == LuaType->LUA_TNIL;
}

sub api_is_string {         #LuaAPI
    my (
        $self,
        $index,             #Int
    ) = @_;
    my $t = $self->api->api_type($index);
    return ( $t == LuaType->LUA_TSTRING || $t == LuaType->LUA_TNUMBER );
}

sub api_is_table {          #LuaAPI
    my (
        $self,
        $index,             #Int
    ) = @_;
    return $self->api->api_type($index) == LuaType->LUA_TTABLE;
}

sub api_is_function {       #LuaAPI
    my (
        $self,
        $index,             #Int
    ) = @_;
    return $self->api->api_type($index) == LuaType->LUA_TFUNCTION;
}

sub compare {               #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub raw_equal {             #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub raw_len {               #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub len {                   #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub push_nil {              #LuaAPI
    my ($self) = @_;
    $self->top->value( new VM::Object::Nil );
    $self->api_incr_top;
}

sub push_boolean {          #LuaAPI
    my (
        $self,
        $b,                 #Bool
    ) = @_;
    $self->top->value( new VM::Object::Boolean( value => $b ) );
    $self->api_incr_top();
}

sub push_number {           #LuaAPI
    my (
        $self,
        $n,                 #Num
    ) = @_;
    $self->top->value( new VM::Object::Number( value => $n ) );
    $self->api_incr_top();
}

sub push_integer {          #LuaAPI
    my (
        $self,
        $n,                 #Num
    ) = @_;
    $self->top->value( new VM::Object::Number( value => $n ) );
    $self->api_incr_top();
}

sub push_unsigned {         #LuaAPI
    my (
        $self,
        $n,                 #Num
    ) = @_;
    $self->top->value( new VM::Object::Number( value => $n ) );
    $self->api_incr_top();
}

sub push_string {           #LuaAPI
    my (
        $self,
        $s,                 #Str
    ) = @_;
    if ( !defined($s) ) {
        $self->api->push_nil;
        return undef;
    }
    else {
        $self->top->value( new VM::Object::String( value => $s ) );
        $self->api_incr_top;
        return $s;
    }
}

sub push_perl_function {    #LuaAPI

    my (
        $self,
        $f,                 #CodeRef
    ) = @_;
    $self->api->push_perl_closure( $f, 0 );
}

sub push_perl_closure {     #LuaAPI
    my (
        $self,
        $f,                 #CodeRef
        $n,                 #Inf
    ) = @_;

    if ( $n == 0 ) {
        $self->top->value( new VM::Object::PClosure( f => $f ) );
    }
    else {
        # perl function with upvalues
        Util->api_check_num_elems( $self, $n );
        Util->api_check( $n <= LuaLimits->MAXUPVAL, "upvalue index too large" );
        my $pcl = new VM::Object::PClosure( f => $f );
        my $src = $self->top - $n;
        while ( $src->index < $self->top->index ) {
            push $pcl->upvals, $src->value_inc;
        }
        $self->top->index( $self->top->index - $n );
        $self->top->value($pcl);
    }
    $self->api_incr_top();
}

=item push_value
Pushes a copy of the element at the given index onto the stack.
=cut

sub push_value {    #LuaAPI
    my (
        $self,
        $index,     #Int
    ) = @_;
    my $addr;       #VM::StkId
    if ( !$self->index2addr( $index, \$addr ) ) {
        Util->invalid_index();
    }
    $self->top->value( $addr->value );
    $self->api_incr_top();
}

sub push_global_table {    #LuaAPI
    my ($self) = @_;
    $self->api->raw_get_i( LuaDef->LUA_REGISTRYINDEX,
        LuaDef->LUA_RIDX_GLOBALS );
}

sub push_light_user_data {    #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub push_uint_64 {            #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub push_thread {             #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub pop {                     #LuaAPI
    my (
        $self,
        $n                    #Int
    ) = @_;
    $self->api->set_top( -$n - 1 );
}

sub get_meta_table {          #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub set_meta_table {          #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub get_global {              #LuaAPI
    my (
        $self,
        $name                 #Str
    ) = @_;
    my $gt    = $self->g->registy->get_int( LuaDef->LUA_RIDX_GLOBALS );
    my $s     = new VM::Object::String( value => $name );
    my $below = $self->top->clone;
    $self->top->value_inc($s);
    $self->v_get_table( $gt, $s, $below );
}

sub set_global {              #LuaAPI
    my (
        $self,
        $name                 #Str
    ) = @_;
    my $gt = $self->g->registy->get_int( LuaDef->LUA_RIDX_GLOBALS );
    my $s = new VM::Object::String( value => $name );
    $self->top->value_inc($s);
    $self->v_set_table( $gt, $s, $self->top - 2 );
    $self->top( $self->top - 2 );
}

sub to_string {               #LuaAPI
    my (
        $self,
        $index                #Int
    ) = @_;
    my $addr;                 #VM::StkId
    if ( !$self->index2addr( $index, \$addr ) ) {
        return undef;
    }
    my $s = Util->as( $addr->value, 'VM::Object::String' );
    if ( !defined($s) ) {
        return $addr->value->to_literal;
    }
    else {
        return $s->value;
    }
}

sub to_number_x {    #LuaAPI
    my (
        $self,
        $index,      #Int
        $is_num      #ScalarRef[Bool]
    ) = @_;
    my $addr;        #VM::StkId
    if ( $self->index2addr( $index, \$addr ) ) {
        $$is_num = 0;    #false
        return 0.0;
    }
    return $addr->value->to_number($is_num);
}

sub to_number {          #LuaAPI
    my (
        $self,
        $index           #Int
    ) = @_;
    my $is_num;
    return $self->api->to_number_x( $index, \$is_num );
}

sub to_integer_x {       #LuaAPI
    my (
        $self,
        $index,          #Int
        $is_num          #ScalarRef[Bool]
    ) = @_;

    my $addr;            #VM::StkId
    if ( $self->index2addr( $index, \$addr ) ) {
        $$is_num = 0;    #false
        return 0.0;
    }
    return int $addr->value->to_number($is_num);
}

sub to_integer {         #LuaAPI
    my (
        $self,
        $index           #Int
    ) = @_;
    my $is_num;
    return $self->api->to_integer_x( $index, \$is_num );
}

sub to_unsigned_x {      #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub to_unsigned {        #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub to_boolean {         #LuaAPI
    my (
        $self,
        $index           #Int
    ) = @_;
    my $addr;            #VM::StkId
    if ( $self->index2addr( $index, \$addr ) ) {
        return 0;
    }
    if ( !defined Util->as( $addr->value, "VM::Object::Nil" ) ) {
        return 0;
    }
    my $b = Util->as( $addr->value, 'VM::Object::Boolean' );
    return !defined($b) || $b->value;
}

sub to_object {          #LuaAPI
    my (
        $self,
        $index           #Int
    ) = @_;
    my $addr;            #VM::StkId
    if ( $self->index2addr( $index, \$addr ) ) {
        return undef;
    }
    return $addr->value;
}

sub to_user_data {       #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub to_thread {          #LuaAPI
    my (
        $self,
        $index           #Int
    ) = @_;
    my $addr;            #VM::StkId
    if ( $self->index2addr( $index, \$addr ) ) {
        return undef;
    }
    return $addr->value->is_thread
      ? Util->as( $addr->value, "VM::State" )
      : undef;
}

sub index2addr {
    my (
        $self,
        $index,          #Int
        $addr,           #ScalarRef[VM::StkId]
    ) = @_;
    my $ci = $self->ci;
    if ( $index > 0 ) {
        $$addr = $ci->func + $index;
        Util->api_check( $index <= $ci->top->index - ( $ci->func->index + 1 ),
            "unacceptable index" );
        if ( ${$addr}->index >= $self->top->index ) {
            return 0;    #false
        }
        else {
            return 1;    #true
        }
    }
    elsif ( $index > LuaDef->LUA_REGISTRYINDEX ) {
        Util->api_check(
            $index != 0
              && -$index <= $self->top->index - ( $ci->func->index + 1 ),
            "invalid index: $index"
        );
        $$addr = $self->top + $index;
        return 1;        #true
    }
    elsif ( $index == LuaDef->LUA_REGISTRYINDEX ) {
        $$addr = new VM::StkId( object => $self->g->registy );
        return 1;        #true
    }

    # upvalues
    else {
        $index = LuaDef->LUA_REGISTRYINDEX - $index;
        Util->api_check( $index <= LuaLimits->MAXUPVAL + 1,
            "upvalue index too large" );
        my $pcl = $ci->func->value;    #VM::Object::PClosure

        if ( defined($pcl) && ( $index <= @{ $pcl->upvals } ) ) {
            $$addr = new VM::StkId( object => $pcl->upvals->[ $index - 1 ] );
            return 1;                  #true
        }
        else {
            $$addr = undef;            #TODO default(StkId)
            return 0;                  #false
        }
    }
}

#end of API part

#DO part
sub d_throw {    #ThreadStatus
    my (
        $self_or_class,
        $err_code,    #Int
    ) = @_;
    die new VM::RuntimeException( err_code => $err_code );
}

sub d_raw_run_protected {
    my (
        $self,
        $func,        #CodeRef
        $ud
    ) = @_;
    my $old_num_perl_calls = $self->num_perl_calls;
    my $res                = ThreadStatus->LUA_OK;
    eval { $func->($ud); };
    if ($@) {
        die $@;
        $self->num_perl_calls($old_num_perl_calls);
        $res = $@->err_code;
    }
    $self->num_perl_calls($old_num_perl_calls);
    return $res;
}

sub set_error_obj {
    my (
        $self,
        $err_code,    #Int
        $old_top,     #VM::StkId
    ) = @_;
    $old_top = $old_top->clone;
    given ($err_code) {
        when ( ThreadStatus->LUA_ERRMEM . '' ) {
            $old_top->value(
                new VM::Object::String( value => "not enough memory" ) );
            break;
        }
        when ( ThreadStatus->LUA_ERRERR . '' ) {
            $old_top->value(
                new VM::Object::String( value => "error in error handling" ) );
            break;
        }
        default { $old_top->value( ( $self->top - 1 )->value ) }
    }
    $self->top( $old_top + 1 );
}

sub d_p_call {
    my (
        $self,
        $func,        #CodeRef
        $ud,
        $old_top,     #VM::StkId
        $err_func,    #Int
    ) = @_;
    $old_top = $old_top->clone;
    my $old_ci                = $self->ci;
    my $old_allow_hook        = $self->allow_hook;
    my $old_num_non_yieldable = $self->num_none_yieldable;
    my $old_err_func          = $self->err_func;

    $self->err_func($err_func);
    my $status = $self->d_raw_run_protected( $func, $ud );
    if ( $status != ThreadStatus->LUA_OK ) {
        $self->f_close($old_top);
        $self->set_error_obj( $status, $old_top );
        $self->ci($old_ci);
        $self->allow_hook($old_allow_hook);
        $self->num_none_yieldable($old_num_non_yieldable);
    }
    $self->err_func($old_err_func);
    return $status;
}

sub d_call {
    my (
        $self,
        $func,           #VM::StkId
        $n_results,      #Int
        $allow_yield,    #Bool
    ) = @_;
    $func = $func->clone;
    if ( $self->num_perl_calls( $self->num_perl_calls + 1 ) >=
        LuaLimits->LUAI_MAXCCALLS )
    {
        if ( $self->num_perl_calls == LuaLimits->LUAI_MAXCCALLS ) {
            $self->g_run_error('Perl Stack Overflow');
        }
        elsif ( $self->num_perl_calls >=
            ( LuaLimits->LUAI_MAXCCALLS + ( LuaLimits->LUAI_MAXCCALLS >> 3 ) ) )
        {
            $self->d_throw( ThreadStatus->LUA_ERRERR );

        }
    }
    if ( !$allow_yield ) {
        $self->num_none_yieldable( $self->num_none_yieldable + 1 );
    }
    if ( !$self->d_pre_call( $func, $n_results ) ) {
        $self->v_execute();
    }
    if ( !$allow_yield ) {
        $self->num_none_yieldable( $self->num_none_yieldable - 1 );
    }
    $self->num_perl_calls( $self->num_perl_calls - 1 );
}

sub d_pre_call {

    #if $func is a perl function, execute it and return true
    #else prepare for Lua call, return false

    my (
        $self,
        $func,         #VM::StkId
        $n_results,    #Int
    ) = @_;
    $func = $func->clone;
    my $cl = Util->as( $func->value, "VM::Object::LClosure" );
    if ( defined($cl) ) {
        my $p = $cl->proto;

        #add nil if the number of argument is not enough
        my $n = ( $self->top->index - $func->index ) - 1;
        for ( ; $n < $p->num_params ; ++$n ) {
            $self->top->value( new VM::Object::Nil );
            $self->top->index( $self->top->index + 1 );
        }

        my $stack_base =
            ( !$p->is_vararg )
          ? ( $func + 1 )
          : $self->adjust_varargs( $p, $n );    #VM::StkId

        $self->ci( $self->extend_ci );
        $self->ci->num_results($n_results);
        $self->ci->func( $func->clone );
        $self->ci->base( $stack_base->clone );
        $self->ci->top( $stack_base + $p->max_stack_size );
        $self->ci->saved_pc( new VM::Pointer( list => $p->code, index => 0 ) );
        $self->ci->call_status( CallStatus->CIST_LUA );

        $self->top( $self->ci->top->clone );

        return 0;                               #false
    }

    my $pcl = Util->as( $func->value, 'VM::Object::PClosure' );
    if ( defined($pcl) ) {

        $self->ci( $self->extend_ci );
        $self->ci->num_results($n_results);
        $self->ci->func( $func->clone );
        $self->ci->top( $self->top + LuaDef->LUA_MINSTACK );
        $self->ci->call_status( CallStatus->CIST_NONE );

        #do the actual call
        my $n = $pcl->f->($self);

        #poscall
        $self->d_pos_call( $self->top - $n );

        return 1;    #true
    }

    #not a function
    #retry with `function' tag method
    $func = $self->try_func_tm($func);

    #now it must be a function
    return $self->d_pre_call( $func, $n_results );
}

sub d_pos_call {
    my (
        $self,
        $first_result,    #VM::StkId
    ) = @_;
    $first_result = $first_result->clone;
    my $ci     = $self->ci;           #VM::CallInfo
    my $res    = $ci->func->clone;    #VM::StkId
    my $wanted = $ci->num_results;

    $self->ci( $ci->previous );
    my $i = $wanted;
    for ( ; $i != 0 && $first_result->index < $self->top->index ; --$i ) {
        $res->value_inc( $first_result->value_inc );
    }
    while ( $i-- > 0 ) {
        $res->value_inc( new VM::Object::Nil );
    }

    $self->top( $res->clone );
    return ( $wanted - LuaDef->LUA_MULTRET );
}

sub extend_ci {
    my ($self) = @_;
    my $ci = new VM::CallInfo;
    $self->ci->next($ci);
    $ci->previous( $self->ci );
    $ci->next(undef);
    return $ci;
}

sub adjust_varargs {
    my (
        $self,
        $p,        #VM::Object::Proto
        $actual    #Int
    ) = @_;
    my $num_fix_args = $p->num_params;
    Util->assert( $actual >= $num_fix_args,
        "AdjustVarargs (actual >= num_fix_args) is false" );

    my $fixed_arg  = $self->top - $actual;    #first fixed argument
    my $stack_base = $self->top->clone;       #final position of first argument
    for ( 1 .. $num_fix_args ) {
        $self->top->value_inc( $fixed_arg->value );
        $fixed_arg->value_inc( new VM::Object::Nil );
    }
    return $stack_base;
}

sub try_func_tm {
    my (
        $self,
        $func,                                #VM::StkId
    ) = @_;
    $func = $func->clone;
    my $tm_obj = $self->t_get_tm_by_obj( $func->value, TMS->TM_CALL );
    if ( !$tm_obj->is_function ) {
        $self->g_type_error( $func, "call" );
    }

    #open a hole inside the stack at `func'
    my $q1 = $self->top - 1;
    my $q2 = $self->top->clone;
    while ( $q2->index > $func->index ) {
        $q2->value( $q1->value );
        $q1->index( $q1->index - 1 );
        $q2->index( $q2->index - 1 );
    }
    $self->incr_top;
    $func->value($tm_obj);
    return $func;
}

#end of DO part

#AuxLib part
BEGIN {
    my $class = __PACKAGE__;
    attr( $class, 0, 'free_list' );    #Int

    # size of the first part of the stack
    attr( $class, 12, 'LEVELS1' );     #Int

    # size of the second part of the stack
    attr( $class, 10, 'LEVELS2' );     #Int
}

sub l_where {
    my ($self) = @_;
    die "#TODO";
}

sub l_error {
    my ($self) = @_;
    die "#TODO";
}

sub l_check_any {
    my ($self) = @_;
    die "#TODO";
}

sub l_check_number {
    my ($self) = @_;
    die "#TODO";
}

sub l_check_integer {
    my ($self) = @_;
    die "#TODO";
}

sub l_check_string {
    my ($self) = @_;
    die "#TODO";
}

sub l_check_unsigned {
    my ($self) = @_;
    die "#TODO";
}

sub l_opt {
    my ($self) = @_;
    die "#TODO";
}

sub l_opt_int {
    my ($self) = @_;
    die "#TODO";
}

sub l_opt_string {
    my ($self) = @_;
    die "#TODO";
}

sub type_error {
    my ($self) = @_;
    die "#TODO";
}

sub tag_error {
    my ($self) = @_;
    die "#TODO";
}

sub l_check_type {
    my ($self) = @_;
    die "#TODO";
}

sub l_arg_check {
    my ($self) = @_;
    die "#TODO";
}

sub l_arg_error {
    my ($self) = @_;
    die "#TODO";
}

sub l_type_name {
    my ($self) = @_;
    die "#TODO";
}

sub l_get_meta_field {
    my ($self) = @_;
    die "#TODO";
}

sub l_call_meta {
    my ($self) = @_;
    die "#TODO";
}

sub push_func_name {
    my ($self) = @_;
    die "#TODO";
}

sub count_levels {
    my ($self) = @_;
    die "#TODO";
}

sub l_trace_back {
    my ($self) = @_;
    die "#TODO";
}

sub l_len {
    my ($self) = @_;
    die "#TODO";
}

sub l_load_buffer {
    my ($self) = @_;
    die "#TODO";
}

sub l_load_buffer_x {
    my ($self) = @_;
    die "#TODO";
}

sub l_load_bytes {
    my (
        $self,
        $bytes,    #
        $name,     #Str
    ) = @_;
    my $load_info = new VM::BytesLoadInfo( bytes => $bytes );
    return $self->load( $load_info, $name, 'binary' );
}

sub err_file {
    return ThreadStatus->LUA_ERRFILE;
}

sub l_load_file {
    my (
        $self,
        $filename,    #Str
    ) = @_;
    return $self->l_load_file_x( $filename, 'binary' );    #TODO 'binary'
}

sub l_load_file_x {
    my (
        $self,
        $filename,                                         #Str
        $mode,                                             #Str
    ) = @_;
    my $status = ThreadStatus->LUA_OK;
    if ( !defined($filename) ) {
        die "stdin uncompleted!";
    }

    my $file_name_index = $self->api->get_top + 1;
    $self->api->push_string( "@" . $filename );
    eval {
        my $load_info = VM::File->open_file($filename);

        #$load_info->skip_comment(); #TODO
        $status =
          $self->api->load( $load_info, $self->api->to_string(-1), $mode );
    };
    if ($@) {
        die $@;    #DEBUG;
        $self->api->push_string("cannot open {$filename}: {$@}");
        return ThreadStatus->LUA_ERRFILE;
    }
    $self->api->remove($file_name_index);
    return $status;
}

sub l_load_string {
    my ($self) = @_;
    die "#TODO";
}

sub l_do_string {
    my ($self) = @_;
    die "#TODO";
}

sub l_do_file {
    my (
        $self,
        $file_name,    #Str
    ) = @_;
    my $status = $self->l_load_file($file_name);
    if ( $status != ThreadStatus->LUA_OK ) {
        return $status;
    }
    return $self->api->p_call( 0, LuaDef->LUA_MULTRET, 0 );
}

sub l_gsub {
    my ($self) = @_;
    die "#TODO";
}

sub l_to_string {
    my ($self) = @_;
    die "#TODO";
}

sub l_open_libs {
    my ($self) = @_;
    my @define = (
        NameFuncPair->new(
            name => Lib::Base->LIB_NAME,
            func => sub { Lib::Base->open_lib(@_); }
        ),
    );
    for my $pair (@define) {
        $self->l_require_f( $pair->name, $pair->func, 1 );
        $self->api->pop(1);
    }

}

sub l_require_f {
    my (
        $self,
        $module_name,    #Str
        $open_func,      #CodeRef
        $global          #Bool
    ) = @_;
    $self->api->push_perl_function($open_func);
    $self->api->push_string($module_name);
    $self->api->call( 1, 1 );
    $self->l_get_sub_table( LuaDef->LUA_REGISTRYINDEX, "_LOADED" );
    $self->api->push_value(-2);
    $self->api->set_field( -2, $module_name );
    $self->api->pop(1);

    if ($global) {
        $self->api->push_value(-1);
        $self->api->set_global($module_name);
    }
}

sub l_get_sub_table {
    my (
        $self,
        $index,     #Int
        $f_name,    #Str
    ) = @_;
    $self->api->get_field( $index, $f_name );
    if ( $self->api->api_is_table(-1) ) {
        return 1;
    }
    else {
        $self->api->pop(1);
        $index = $self->api->abs_index($index);
        $self->api->new_table();
        $self->api->push_value(-1);
        $self->api->set_field( $index, $f_name );
        return 0;
    }
}

sub l_new_lib_table {
    my ($self) = @_;
    die "#TODO";
}

sub l_new_lib {
    my ($self) = @_;
    die "#TODO";
}

=item l_set_funcs
Registers all functions in the array l (see luaL_Reg) into the table on 
the top of the stack (below optional upvalues, see next).

When nup is not zero, all functions are created sharing nup upvalues, 
which must be previously pushed on the stack on top of the library table. 
These values are popped from the stack after the registration.

=cut

sub l_set_funcs {
    my (
        $self,
        $define,    #ArrayRef[Common::NameFuncPair]
        $nup,       #Int
    ) = @_;
    for my $pair (@$define) {
        for ( 1 .. $nup ) {
            $self->api->push_value( -$nup );
        }
        $self->api->push_perl_closure( $pair->func, $nup );
        $self->api->set_field( -( $nup + 2 ), $pair->name );
    }
    $self->api->pop($nup);
}

sub find_field {
    my ($self) = @_;
    die "#TODO";
}

sub push_global_func_name {
    my ($self) = @_;
    die "#TODO";
}

sub l_ref {
    my ($self) = @_;
    die "#TODO";
}

sub l_unref {
    my ($self) = @_;
    die "#TODO";
}

#end of AuxLib part

#Func part
sub f_find_upval {
    my ($self) = @_;
    die "#TODO";

    #my $node = $self->open_upval->[0];
    #my $prev = Undef;

    #while(defined($node)){
    #my $upval
    #}
}

sub f_close {
    my (
        $self,
        $level    #VM::StkId
    ) = @_;
    $level = $level->clone;
    my $node = $self->open_upval->[0];
    while ( defined($node) ) {
        my $upval = $node->value;
        if ( $upval->v->index < $level->index ) {
            last;
        }
        shift $self->open_upval;
        my $node = $self->open_upval->[0];

        $upval->value->[0] = $upval->v->value;
        $upval->v( new VM::StkId( $upval->value, 0 ) );
    }
}

sub f_get_local_name {
    my (
        $self,
        $proto,           #VM::Object::Proto
        $local_number,    #Int
        $pc,              #Int
    ) = @_;
    for (
        my $i = 0 ;
        $i < @{ $proto->loc_vars } && $proto->loc_vars->[$i]->start_pc <= $pc ;
        ++$i
      )
    {
        if ( $pc < $proto->loc_vars->[$i]->end_pc )
        {                 # is variable still active?
            --$local_number;
            if ( $local_number == 0 ) {
                return $proto->loc_vars->[$i]->var_name;
            }

        }

    }
    return undef;
}

#end of Func part

#VM part

sub v_execute {
    my ($self) = @_;
    my $env    = new VM::ExecuteEnvironment;
    my $ci     = $self->ci;
  newframe:
    my $cl = Util->as( $ci->func->value, 'VM::Object::LClosure' );
    $env->k( new VM::StkId( list => $cl->proto->k, index => 0 ) );
    $env->base( $ci->base->clone );

    while (1) {
        my $i = $ci->saved_pc->value_inc;    #VM::Instruction
        $env->i( $i->clone );
        my $ra = $env->RA;
        $self->dump_stack( $env->base->index );

        given ( $i->GET_OPCODE() ) {
            when ( OpCode->OP_MOVE . '' ) {
                my $rb = $env->RB;
                $ra->value( $rb->value );
                break;
            }
            when ( OpCode->OP_LOADK . '' ) {
                my $rb = $env->k + $i->GETARG_Bx();    #VM::StkId
                $ra->value( $rb->value );
                break;
            }
            when ( OpCode->OP_LOADKX . '' )   { die "#TODO"; }
            when ( OpCode->OP_LOADBOOL . '' ) { die "#TODO"; }
            when ( OpCode->OP_LOADNIL . '' )  { die "#TODO"; }
            when ( OpCode->OP_GETUPVAL . '' ) { die "#TODO"; }
            when ( OpCode->OP_GETTABUP . '' ) { die "#TODO"; }
            when ( OpCode->OP_GETTABLE . '' ) { die "#TODO"; }
            when ( OpCode->OP_SETTABUP . '' ) {
                my $a   = $i->GETARG_A();
                my $key = $env->RKB;
                my $val = $env->RKC;
                $self->v_set_table( $cl->upvals->[$a]->v->value,
                    $key->value, $val );
                $env->base( $ci->base->clone );
                break;
            }
            when ( OpCode->OP_SETUPVAL . '' ) { die "#TODO"; }
            when ( OpCode->OP_SETTABLE . '' ) { die "#TODO"; }
            when ( OpCode->OP_NEWTABLE . '' ) { die "#TODO"; }
            when ( OpCode->OP_SELF . '' )     { die "#TODO"; }
            when ( OpCode->OP_ADD . '' )      { die "#TODO"; }
            when ( OpCode->OP_SUB . '' )      { die "#TODO"; }
            when ( OpCode->OP_MUL . '' )      { die "#TODO"; }
            when ( OpCode->OP_DIV . '' )      { die "#TODO"; }
            when ( OpCode->OP_MOD . '' )      { die "#TODO"; }
            when ( OpCode->OP_POW . '' )      { die "#TODO"; }
            when ( OpCode->OP_UNM . '' )      { die "#TODO"; }
            when ( OpCode->OP_NOT . '' )      { die "#TODO"; }
            when ( OpCode->OP_LEN . '' )      { die "#TODO"; }
            when ( OpCode->OP_CONCAT . '' )   { die "#TODO"; }
            when ( OpCode->OP_JMP . '' ) {
                $self->v_do_jump( $ci, $i, 0 );
                break;
            }
            when ( OpCode->OP_EQ . '' )       { die "#TODO"; }
            when ( OpCode->OP_LT . '' )       { die "#TODO"; }
            when ( OpCode->OP_LE . '' )       { die "#TODO"; }
            when ( OpCode->OP_TEST . '' )     { die "#TODO"; }
            when ( OpCode->OP_TESTSET . '' )  { die "#TODO"; }
            when ( OpCode->OP_CALL . '' )     { die "#TODO"; }
            when ( OpCode->OP_TAILCALL . '' ) { die "#TODO"; }
            when ( OpCode->OP_RETURN . '' ) {
                my $b = $i->GETARG_B();
                if ( $b != 0 ) {
                    $self->top( $ra + $b - 1 );
                }
                if ( @{ $cl->proto->p } > 0 ) {
                    $self->f_close( $env->base );
                }
                $b = $self->d_pos_call($ra);
                if ( ( $ci->call_status & CallStatus->CIST_REENTRY ) == 0 ) {

                    return;
                }
                else {
                    $ci = $self->ci;
                    if ( $b != 0 ) {
                        $self->top( $ci->top->clone );
                        goto 'newframe';
                    }
                }
            }
            when ( OpCode->OP_FORLOOP . '' )  { die "#TODO"; }
            when ( OpCode->OP_FORPREP . '' )  { die "#TODO"; }
            when ( OpCode->OP_TFORCALL . '' ) { die "#TODO"; }
            when ( OpCode->OP_TFORLOOP . '' ) { die "#TODO"; }
            when ( OpCode->OP_SETLIST . '' )  { die "#TODO"; }
            when ( OpCode->OP_CLOSURE . '' )  { die "#TODO"; }
            when ( OpCode->OP_VARARG . '' )   { die "#TODO"; }
            when ( OpCode->OP_EXTRAARG . '' ) { die "#TODO"; }
            default                           { die "#TODO"; }
        }
    }

}

sub v_not_implemented {
    my ($self) = @_;
    die "#TODO";
}

sub fast_tm {    #$tm=>TMS
    my (
        $self,
        $et,     #VM::Object::Table
        $tm      #Int
    ) = @_;
    if ( !defined($et) ) {
        return undef;
    }

    if ( ( $et->flags & ( 1 << $tm ) ) != 0 ) {
        return undef;
    }

    return $self->t_get_tm( $et, $tm );
}

sub v_get_table {
    my (
        $self,
        $t,      #VM::Object
        $key,    #VM::Object
        $val,    #VM::StkId
    ) = @_;
    $val = $val->clone;
    for ( 1 .. LuaConf->MAXTAGLOOP ) {
        my $tm_obj;    #VM::Object;
        my $tbl = Util->as( $t, 'VM::Object::Table' );
        if ( defined($tbl) ) {
            my $res = $tbl->get($key);
            if ( !$res->is_nil ) {
                $val->value($res);
                return;
            }
            $tm_obj = $self->fast_tm( $tbl->meta_table, TMS->TM_INDEX );
            if ( !defined($tm_obj) ) {
                $val->value($res);
                return;
            }

            # else will try the tagmethod
        }
        else {
            $tm_obj = $self->t_get_tm_by_obj( $t, TMS->TM_INDEX );
            if ( $tm_obj->is_nil ) {
                $self->g_simple_type_error( $t, "index" );
            }
        }

        if ( $tm_obj->is_function ) {
            $self->call_tm( $tm_obj, $t, $key, $val, 1 );
            return;
        }
        $t = $tm_obj;
    }
    $self->g_run_error('loop in gettable');
}

sub v_set_table {
    my (
        $self,
        $t,      #VM::Object
        $key,    #VM::Object
        $val,    #VM::StkId
    ) = @_;
    $val = $val->clone;
    for ( 1 .. LuaConf->MAXTAGLOOP ) {
        my $tm_obj;    #VM::Object
        my $tbl = Util->as( $t, "VM::Object::Table" );
        if ( defined($tbl) ) {
            my $old_val = $tbl->get($key);
            if ( !$old_val->is_nil ) {
                $tbl->set( $key, $val->value );
                return;
            }

            #check metamethod
            $tm_obj = $self->fast_tm( $tbl->meta_table, TMS->TM_NEWINDEX );
            if ( !defined($tm_obj) ) {
                $tbl->set( $key, $val->value );
                return;
            }

            # else will try the tagmethod
        }
        else {
            $tm_obj = $self->t_get_tm_by_obj( $t, TMS->TM_INDEX );
            if ( $tm_obj->is_nil ) {
                $self->g_simple_type_error( $t, "index" );
            }
        }

        if ( $tm_obj->is_function ) {
            $self->call_tm( $tm_obj, $t, $key, $val, 1 );
            return;
        }
        $t = $tm_obj;
    }
    $self->g_run_error('loop in gettable');
}

sub v_push_closure {
    my ($self) = @_;
    die "#TODO";
}

sub v_obj_len {
    my ($self) = @_;
    die "#TODO";
}

sub v_concat {
    my ($self) = @_;
    die "#TODO";
}

sub v_do_jump {
    my (
        $self,
        $ci,    #VM::CallInfo
        $i,     #VM::Instruction
        $e,     #Int
    ) = @_;
    my $a = $i->GETARG_A;
    if ( $a > 0 ) {
        $self->f_close( $ci->base + ( $a - 1 ) );
    }
    $ci->saved_pc( $ci->saved_pc + ( $i->GETARG_sBx + $e ) );
}

sub v_do_next_jump {
    my ($self) = @_;
    die "#TODO";
}

sub v_to_number {
    my ($self) = @_;
    die "#TODO";
}

sub tms2op {    #$op=>TMS
    my (
        $self,
        $op     #Int
    ) = @_;
    given ($op) {
        when ( TMS->TM_ADD . '' ) { return LuaOp->LUA_OPADD; }
        when ( TMS->TM_SUB . '' ) { return LuaOp->LUA_OPSUB; }
        when ( TMS->TM_MUL . '' ) { return LuaOp->LUA_OPMUL; }
        when ( TMS->TM_DIV . '' ) { return LuaOp->LUA_OPDIV; }
        when ( TMS->TM_POW . '' ) { return LuaOp->LUA_OPPOW; }
        when ( TMS->TM_UNM . '' ) { return LuaOp->LUA_OPUNM; }
        default                   { die __FILE__ . ':' . __LINE__; }
    }
}

sub call_tm {
    my (
        $self,
        $f,         #VM::Object
        $p1,        #VM::Object
        $p2,        #VM::Object
        $p3,        #VM::StkId
        $has_res    #Bool
    ) = @_;
    $p3 = $p3->clone;
    my $func = $self->top->clone;
    $self->top->value_inc($f);     #push function
    $self->top->value_inc($p1);    #push 1st argument
    $self->top->value_inc($p2);    #push 2nd argument
    if ( !$has_res ) {
        $self->top->value_inc( $p3->value );
    }
    $self->d_call( $func, ( $has_res ? 1 : 0 ), $self->ci->is_lua );
    if ($has_res) {

        #move result to its place
        my $below = $self->top - 1;
        $p3->value( $below->value );
        $self->top( $self->top - 1 );
    }

}

sub call_bin_tm {    #$tm=>TMS
    my (
        $self,
        $p1,         #VM::StkId
        $p2,         #VM::StkId
        $res,        #VM::StkId
        $tm          #Int
    ) = @_;
    $p1  = $p1->clone;
    $p2  = $p2->clone;
    $res = $res->clone;
    my $tm_obj = $self->t_get_tm_by_obj( $p1->value, $tm );
    if ( $tm_obj->is_nil ) {
        $tm_obj = $self->t_get_tm_by_obj( $p1->value, $tm );
    }
    if ( $tm_obj->is_nil ) {
        return 0;    #false;
    }

    $self->call_tm( $tm_obj, $p1->value, $p2->value, $res, 1 );
    return 1;        #true
}

sub v_arith {        #$op=>TMS

    my (
        $self,
        $ra,         #VM::StkId
        $rb,         #VM::StkId
        $rc,         #VM::StkId
        $op          #Int
    ) = @_;
    $ra = $ra->clone;
    $rb = $rb->clone;
    $rc = $rc->clone;
    my $b = $self->v_to_number( $rb->value );
    my $c = $self->v_to_number( $rc->value );
    if ( defined($b) && defined($c) ) {
        my $res = $self->o_arith( $self->tms2op($op), $b->value, $c->value );
        $ra->value( new VM::Object::Number( value => $res ) );
    }
    elsif ( !$self->call_bin_tm( $rb, $rc, $ra, $op ) ) {
        $self->g_arith_error( $rb, $rc );
    }
}

sub call_order_tm {
    my ($self) = @_;
    die "#TODO";
}

sub v_less_than {
    my ($self) = @_;
    die "#TODO";
}

sub v_less_equal {
    my ($self) = @_;
    die "#TODO";
}

sub v_finish_op {
    my ($self) = @_;
    die "#TODO";
}

sub v_raw_equal_obj {
    my ($self) = @_;
    die "#TODO";
}

sub equal_obj {
    my ($self) = @_;
    die "#TODO";
}

sub get_equal_tm {
    my ($self) = @_;
    die "#TODO";
}

sub v_equal_object {
    my ($self) = @_;
    die "#TODO";
}

#end of VM part

#TagMethod part
sub get_tag_method_name {    #$tm=>TMS
    my (
        $self,
        $tm                  #Int
    ) = @_;
    given ($tm) {
        when ( TMS->TM_INDEX . '' )    { return "__index"; }
        when ( TMS->TM_NEWINDEX . '' ) { return "__newindex"; }
        when ( TMS->TM_GC . '' )       { return "__gc"; }
        when ( TMS->TM_MODE . '' )     { return "__mode"; }
        when ( TMS->TM_LEN . '' )      { return "__len"; }
        when ( TMS->TM_EQ . '' )       { return "__eq"; }
        when ( TMS->TM_ADD . '' )      { return "__add"; }
        when ( TMS->TM_SUB . '' )      { return "__sub"; }
        when ( TMS->TM_MUL . '' )      { return "__mul"; }
        when ( TMS->TM_DIV . '' )      { return "__div"; }
        when ( TMS->TM_MOD . '' )      { return "__mod"; }
        when ( TMS->TM_POW . '' )      { return "__pow"; }
        when ( TMS->TM_UNM . '' )      { return "__unm"; }
        when ( TMS->TM_LT . '' )       { return "__lt"; }
        when ( TMS->TM_LE . '' )       { return "__le"; }
        when ( TMS->TM_CONCAT . '' )   { return "__concat"; }
        when ( TMS->TM_CALL . '' )     { return "__call"; }
        default                        { die __FILE__ . ':' . __LINE__; }
    }
}

sub t_get_tm {    #$tm=>TMS
    my (
        $self,
        $mt,      #VM::Object::Table
        $tm       #Int
    ) = @_;
    if ( !defined($mt) ) {
        return undef;
    }
    my $res = $mt->get_str( $self->get_tag_method_name($tm) );
    if ( $res->is_nil ) {    # no tag method?
        $mt->flags( $mt->flags | ( 1 << $tm ) );
        return undef;
    }
    else {
        return $res;
    }
}

sub t_get_tm_by_obj {        #$tm=>TMS
    my (
        $self,
        $o,                  #VM::Object
        $tm                  #Int
    ) = @_;
    my $mt;                  #VM::Object::Table
    given ( $o->type ) {
        when ( LuaType->LUA_TTABLE . '' ) {
            $mt = $o->meta_table;
            break;
        }
        when ( LuaType->LUA_TUSERDATA . '' ) {
            $mt = $o->meta_table;
            break;
        }
        default {
            $mt = $self->g->meta_tables->[ $o->type ];
            break;
        }
    }
    return defined($mt)
      ? $mt->get_str( $self->get_tag_method_name($tm) )
      : VM::Object::Nil->new;
}

#end of TagMethod part

#Debug part
sub get_stack {    #LuaAPI
    my ($self) = @_;
    die "#TODO";
}

sub get_info {
    my ($self) = @_;
    die "#TODO";
}

sub aux_get_info {
    my ($self) = @_;
    die "#TODO";
}

sub collect_valid_lines {
    my ($self) = @_;
    die "#TODO";
}

sub get_func_name {
    my ($self) = @_;
    die "#TODO";
}

sub func_info {
    my ($self) = @_;
    die "#TODO";
}

sub add_info {
    my (
        $self,
        $msg    #Str
    ) = @_;
    if ( $self->ci->is_lua ) {
        my $line = $self->ci->current_line;
        my $src  = $self->ci->current_lua_func->proto->source;
        if ( !defined($src) ) {
            $src = "?";
        }

        # we cannot use `push_string' here, one of APIs,
        # in which `api_incr_top' will check if `top'
        # is greater than `ci->top'
        $self->o_push_string("{$src}:{$line}: {$msg}");
    }
}

sub g_run_error {
    my (
        $self,
        $msg    #Str
    ) = @_;
    $self->add_info($msg);
    $self->g_error_msg();
}

sub g_error_msg {
    my ($self) = @_;
    if ( $self->err_func != 0 ) {    #is there an error handling funcion?
        my $err_func = $self->restore_stack( $self->err_func );

        my $lcl = Util->as( $err_func->value, 'VM::Object::LClosure' );
        my $pcl = Util->as( $err_func->value, 'VM::Object::PClosure' );
        if ( !defined($lcl) && !defined($pcl) ) {
            $self->d_throw( ThreadStatus->LUA_ERRERR );
        }
        my $below = $self->top - 1;
        $self->top->value( $below->value );
        $below->value( $err_func->value );
        $self->incr_top();

        $self->d_call( $below, 1, 0 );
    }
}

sub upval_name {
    my ($self) = @_;
    die "#TODO";

}

sub get_upvalue_name {
    my ($self) = @_;
    die "#TODO";

}

sub k_name {
    my ($self) = @_;
    die "#TODO";

}

sub find_set_reg {
    my ($self) = @_;
    die "#TODO";
}

sub get_obj_name {
    my ($self) = @_;
    die "#TODO";
}

sub is_in_stack {
    my ($self) = @_;
    die "#TODO";
}

sub g_simple_type_error {
    my (
        $self,
        $o,    #VM::Object
        $op    #Str
    ) = @_;
    my $t = $self->obj_type_name($o);
    $self->g_run_error("attempt to {$op} a {$t} value");
}

sub g_type_error {
    my (
        $self,
        $o,    #VM::StkId
        $op    #Str
    ) = @_;
    $o = $o->clone;
    my $ci = $self->ci;
    my $name;
    my $kind;
    my $t = $self->obj_type_name( $o->value );
    if ( $ci->is_lua ) {
        $kind = $self->get_upvalue_name( $ci, $o, \$name );
        if ( defined($kind) && $self->is_in_stack( $ci, $o ) ) {
            my $lcl = Util->as( $ci->func->value, "VM::Object::LClosure" );
            $kind = $self->get_obj_name( $lcl->proto, $ci->current_pc,
                ( $o->index - $ci->base->index ), \$name );
        }
    }
    if ( defined($kind) ) {
        $self->g_run_error("attempt to {$op} {$kind} '{$name}'(a {$t} value)");
    }
    else {
        $self->g_run_error("attempt to {$op} a {$t} value");

    }
}

sub g_arith_error {
    my ($self) = @_;
    die "#TODO";
}

sub g_order_error {
    my ($self) = @_;
    die "#TODO";
}

sub g_concate_error {
    my ($self) = @_;
    die "#TODO";
}

#end of Debug part

1;
