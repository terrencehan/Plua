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
    use VM::LoadInfo;
    use VM::Undump;
    use VM::File;
    use VM::LoadParameter;
    use VM::Object::Nil;
    use VM::Object::Proto;
    use VM::Object::LClosure;
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

    method BUILD {
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
    }

    method o_arith (Int $op, Num $v1, Num $v2 ) {    #$op=>LuaOp
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

    method o_str2decimal (Str $s, ScalarRef[Num] $result) {  #return Bool
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
        isa     => 'ArrayRef[VM::Object::Upvalue|Undef]',
        default => sub { [] },
    );

    has 'instruction_history' => (    #queue
        is      => 'rw',
        isa     => 'ArrayRef[VM::Instruction]',
        default => sub { [] },
    );

    has 'api' => (
        is => 'rw',

        #isa => 'VM::LuaAPI',
        isa => 'VM::State',
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
        $self->g->registy->set_int( LuaDef->LUA_RIDX_MAINTHREAD, $self );
        $self->g->registy->set_int( LuaDef->LUA_RIDX_MAINTHREAD,
            new VM::Object::Table );
    }

    method incr_top {
        $self->top->index( $self->top->index + 1 );
    }

    method restore_stack (Int $index) {
        return new VM::StkId( list => $self->state_stack, index => $index );
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

    method dump_stack {
                              #TODO for debug purpose
    }

    method dump_stack_to_string {
        die "#TODO";
    }

    #API part:
    method new_thread {              #LuaAPI
        my $new_lua = new VM::State( g => $self->g );
        $self->top->value($new_lua);
        $self->api_incr_top();

        $new_lua->hook_mask( $self->hook_mask );
        $new_lua->base_hook_count( $self->base_hook_count );
        $new_lua->hook( $self->hook );
        $new_lua->reset_hook_count();

        return $new_lua;
    }

    method check_mode (Str|Undef $given, Str $expected) {
        if ( defined($given) && $given ne $expected ) {
            $self->o_push_string(
                "attempt to load a $expected chunk (mode is '{$given}'");
            $self->d_throw( ThreadStatus->LUA_ERRSYNTAX );
        }
    }

    method f_load ($ud) {
        my $param = $ud;
        my $proto;
        my $c = $param->load_info->peek_byte;

        #if ( $c == LuaConf->LUA_SIGNATURE ) {
        if (1) {        #TODO
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
        Util->assert(
            scalar @{ $cl->upvals } == scalar @{ $cl->proto->upvalues } );

        ## initialize upvalues
        for ( my $i = 0 ; $i < scalar @{ $proto->upvals } ; ++$i ) {
            $cl->upvals->[$i] = new VM::Object::Upvalue;
        }

        $self->top->value($cl);
        $self->incr_top();
    }

    method load (VM::LoadInfo $load_info, Str $name, Str $mode) { #LuaAPI
        my $param = new VM::LoadParameter(
            load_info => $load_info,
            name      => $name,
            mode      => $mode,
        );

        my $status = $self->d_p_call( sub { $self->f_load(@_) },
            $param, $self->top, $self->err_func );

        if ( $status == ThreadStatus->LUA_OK ) {
            my $cl =
              Util->as( ( $self->top - 1 )->value, 'VM::Object::LClosure' );
            if ( defined($cl) && @{ $cl->upvals } == 1 ) {
                $cl->upvals->[0]->v->value(
                    $self->g->registy->get_int( LuaDef->LUA_RIDX_GLOBALS ) );
            }
        }

        return $status;
    }

    method dump {    #LuaAPI

        die "#TODO";
    }

    method get_context {    #LuaAPI

        die "#TODO";

    }

    method call (Int $num_args, Int $num_results) {           #LuaAPI
        $self->api->call_k( $num_args, $num_results );
    }

    method call_k (Int $num_args, Int $num_results, Int $context, CodeRef |Undef $continue_func) { #LuaAPI
        Util->api_check(
            !defined($continue_func) || !$self->ci->is_lua,
            "cannot use continuations inside hooks"
        );
        Util->api_check_num_elems( $self, $num_args + 1 );
        Util->api_check(
            self->status == ThreadStatus->LUA_OK,
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

    method f_call {
        die "#TODO";
    }

    method check_results (Int $num_args, Int $num_results ) {
        Util->api_check(
            $num_results == LuaDef->LUA_MULTRET
              || $self->ci->top->index - $self->top->index >=
              $num_results - $num_args,
            "results from function overflow current stack size"
        );
    }

    method p_call (Int $num_args, Int $num_results, Int $err_func) {    #LuaAPI
        return $self->api->p_call_k( $num_args, $num_results, $err_func, 0,
            undef );
    }

    method p_call_k (Int $num_args, Int $num_results, Int $err_func, Int $context, CodeRef $continue_func) { #LuaAPI
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
        $c->func = $self->top - ( $num_args + 1 );
        if ( !defined($continue_func) || $self->num_none_yieldable > 0 )
        {                #no continuatoin or no yieldable?
            $c->num_results($num_results);
            $status = $self->d_p_call( $self->f_call, $c, $c->func, $func );
        }
        else {
            my $ci = $self->ci;
            $ci->continue_func($continue_func);
            $ci->context($context);
            $ci->extra( $c->func );
            $ci->old_allow_hook( $self->allow_hook );
            $ci->old_err_func( $self->err_func );
            $self->err_func($func);
            $ci->call_status( $ci->call_status | CallStatus->CIST_YPCALL );
            $self->d_call( $c->func, $num_results, 1 );
            $ci->call_status( $ci->call_status & ( ~CallStatus->CIST_YPCALL ) );
            $self->err_func( $ci->old_err_func );
            $status = ThreadStatus->LUA_OK;
        }
        $self->adjust_results($num_results);
        return $status;
    }

    method finish_perl_call {
        die "#TODO";
    }

    method unroll {
        die "#TODO";
    }

    method resume_err {
        die "#TODO";
    }

    method find_p_call {
        die "#TODO";
    }

    method recover {
        die "#TODO";
    }

    method _resume {             #name conflict with API method
        die "#TODO";
    }

    method resume {              #LuaAPI
        die "#TODO";
    }

    method yield {               #LuaAPI
        die "#TODO";
    }

    method yield_k {             #LuaAPI
        die "#TODO";
    }

    method abs_index {           #LuaAPI
        die "#TODO";
    }

    method get_top {             #LuaAPI
        return $self->top->index - ( $self->ci->func->index + 1 );
    }

    method set_top {             #LuaAPI
        die "#TODO";
    }

    method remove {              #LuaAPI
        die "#TODO";
    }

    method insert {              #LuaAPI
        die "#TODO";
    }

    method move_to {
        die "#TODO";
    }

    method replace {             #LuaAPI
        die "#TODO";
    }

    method copy {                #LuaAPI
        die "#TODO";
    }

    method x_move {              #LuaAPI
        die "#TODO";
    }

    method error {               #LuaAPI
        die "#TODO";
    }

    method upvalue_index {       #LuaAPI
        die "#TODO";
    }

    method get_upvalue {         #LuaAPI
        die "#TODO";
    }

    method set_upvalue {         #LuaAPI
        die "#TODO";
    }

    method create_table {        #LuaAPI
        die "#TODO";
    }

    method new_table {           #LuaAPI
        die "#TODO";
    }

    method next {                #LuaAPI
        die "#TODO";
    }

    method raw_get_i (Int $index, Int $n) {           #LuaAPI
        my $addr;             #VM::StkId
        if ( !$self->index2addr( $index, \$addr ) ) {
            Util->api_check( 0, "table expected" );
        }

        my $tbl = Util->as( $addr->value, 'VM::Object::Table' );
        Util->api_check( defined($tbl), "table expected" );
        $self->top->value( $tbl->get_int($n) );
        $self->api_incr_top;
    }

    method debug_get_instruction_history {    #LuaAPI
        die "#TODO";
    }

    method raw_get {                          #LuaAPI
        die "#TODO";
    }

    method raw_set_i {                        #LuaAPI
        die "#TODO";
    }

    method raw_set {                          #LuaAPI
        die "#TODO";
    }

=item get_field
Pushes onto the stack the value t[k],  where t is the value at the 
given index. As in Lua,  this function may trigger a metamethod for 
the "index" event
=cut

    method get_field {                        #LuaAPI
        die "#TODO";
    }

=item set_field
Does the equivalent to t[k] = v,  where t is the value at the given 
index and v is the value at the top of the stack.  This function pops 
the value from the stack. As in Lua, this function may trigger a 
metamethod for the "newindex" event
=cut

    method set_field (Int $index, Str $key) {    #LuaAPI
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

    method concat {    #LuaAPI
        die "#TODO";
    }

    method api_type (Int $index) { #name conflict with attr "type"                            #LuaAPI
        my $addr;    #VM::StkId
        if ( !$self->index2addr( $index, \$addr ) ) {
            return LuaType->LUA_TNONE;
        }

        return $addr->value->type;
    }

    method type_name (Int $t) {    #LuaAPI
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

    method obj_type_name (VM::Object $o) {
        return $self->type_name( $o->type );
    }

    method o_push_string (Str $s) {
        $self->top->value( new VM::Object::String( value => $s ) );
        $self->incr_top;
    }

    method api_is_nil (Int $index) {       #LuaAPI
        return $self->api->api_type($index) == LuaType->LUA_TNIL;
    }

    method api_is_none (Int $index) {      #LuaAPI
        return $self->api->api_type($index) == LuaType->LUA_TNONE;
    }

    method api_is_none_or_nil (Int $index) {    #LuaAPI
        my $t = $self->api->api_type($index);
        return $t == LuaType->LUA_TNONE || $t == LuaType->LUA_TNIL;
    }

    method api_is_string (Int $index) {         #LuaAPI
        my $t = $self->api->api_type($index);
        return ( $t == LuaType->LUA_TSTRING || $t == LuaType->LUA_TNUMBER );
    }

    method api_is_table (Int $index) {          #LuaAPI
        return $self->api->api_type($index) == LuaType->LUA_TTABLE;
    }

    method api_is_function (Int $index) {       #LuaAPI
        return $self->api->api_type($index) == LuaType->LUA_TFUNCTION;
    }

    method compare {               #LuaAPI
        die "#TODO";
    }

    method raw_equal {             #LuaAPI
        die "#TODO";
    }

    method raw_len {               #LuaAPI
        die "#TODO";
    }

    method len {                   #LuaAPI
        die "#TODO";
    }

    method push_nil {              #LuaAPI
        $self->top->value( new VM::Object::Nil );
        $self->api_incr_top;
    }

    method push_boolean {          #LuaAPI
        die "#TODO";
    }

    method push_number {           #LuaAPI
        die "#TODO";
    }

    method push_integer {          #LuaAPI
        die "#TODO";
    }

    method push_unsigned {         #LuaAPI
        die "#TODO";
    }

    method push_string (Str $s) {           #LuaAPI
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

    method push_perl_function (CodeRef $f) {    #LuaAPI

        $self->api->push_perl_closure( $f, $0 );
    }

    method push_perl_closure (CodeRef $f, Int $n) {     #LuaAPI

        if ( $n == 0 ) {
            $self->top->value( new VM::Object::PClosure( f => $f ) );
        }
        else {
            # perl function with upvalues
            Util->api_check_num_elems( $self, $n );
            Util->api_check( $n <= LuaLimits->MAXUPVAL,
                "upvalue index too large" );
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

    method push_value (Int $index) {    #LuaAPI
        my $addr;       #VM::StkId
        if ( !$self->index2addr( $index, \$addr ) ) {
            Util->invalid_index();
        }
        $self->top->value( $addr->value );
        $self->api_incr_top();
    }

    method push_global_table {    #LuaAPI
        $self->api->raw_get_i( LuaDef->LUA_REGISTRYINDEX,
            LuaDef->LUA_RIDX_GLOBALS );
    }

    method push_light_user_data {    #LuaAPI
        die "#TODO";
    }

    method push_uint_64 {            #LuaAPI
        die "#TODO";
    }

    method push_thread {             #LuaAPI
        die "#TODO";
    }

    method pop {                     #LuaAPI
        die "#TODO";
    }

    method get_meta_table {          #LuaAPI
        die "#TODO";
    }

    method set_meta_table {          #LuaAPI
        die "#TODO";
    }

    method get_global {              #LuaAPI
        die "#TODO";
    }

    method set_global {              #LuaAPI
        die "#TODO";
    }

    method to_string (Int $index) {               #LuaAPI
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

    method to_number_x {    #LuaAPI
        die "#TODO";
    }

    method to_number {      #LuaAPI
        die "#TODO";
    }

    method to_integer_x {    #LuaAPI
        die "#TODO";
    }

    method to_integer {      #LuaAPI
        die "#TODO";
    }

    method to_unsigned_x {    #LuaAPI
        die "#TODO";
    }

    method to_unsigned {      #LuaAPI
        die "#TODO";
    }

    method to_boolean {       #LuaAPI
        die "#TODO";
    }

    method to_object {        #LuaAPI
        die "#TODO";
    }

    method to_user_data {     #LuaAPI
        die "#TODO";
    }

    method to_thread {        #LuaAPI
        die "#TODO";
    }

    method index2addr (Int $index, ScalarRef[VM::StkId|Undef] $addr) {
        my $ci = $self->ci;
        if ( $index > 0 ) {
            $$addr = $ci->func + $index;
            Util->api_check(
                $index <= $ci->top->index - ( $ci->func->index + 1 ),
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
            Util->api_check(
                $index <= LuaLimits->MAXUPVAL + 1,
                "upvalue index too large"
            );
            my $pcl = $ci->func->value;    #VM::Object::PClosure

            if ( defined($pcl) && ( $index <= @{ $pcl->upvals } ) ) {
                $$addr =
                  new VM::StkId( object => $pcl->upvals->[ $index - 1 ] );
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
    method d_throw (Int $err_code) {    #ThreadStatus
        die new VM::RuntimeException( err_code => $err_code );
    }

    method d_raw_run_protected (CodeRef $func, $ud) {
        my $old_num_perl_calls = $self->num_perl_calls;
        my $res                = ThreadStatus->LUA_OK;
        eval { $func->($ud); };
        if ($@) {
            $self->num_perl_calls($old_num_perl_calls);
            $res = $@->err_code;
        }
        $self->num_perl_calls($old_num_perl_calls);
        return $res;
    }

    method set_error_obj (Int $err_code, VM::StkId $old_top) {
        given ($err_code) {
            when ( ThreadStatus->LUA_ERRMEM . '' ) {
                $old_top->value(
                    new VM::Object::String( value => "not enough memory" ) );
                break;
            }
            when ( ThreadStatus->LUA_ERRERR . '' ) {
                $old_top->value(
                    new VM::Object::String( value => "error in error handling" )
                );
                break;
            }
            default { $old_top->value( ( $self->top - 1 )->value ) }
        }
        $self->top( $old_top + 1 );
    }

    method d_p_call (CodeRef $func, $ud, VM::StkId $old_top, Int $err_func) {
        my $old_ci                = $self->CI;
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

    method d_call (VM::StkId $func, Int $n_results, Bool $allow_yield) {
        if ( $self->num_perl_calls( $self->num_perl_calls + 1 ) >=
            LuaLimits->LUAI_MAXCCALLS )
        {
            if ( $self->num_perl_calls == LuaLimits->LUAI_MAXCCALLS ) {
                $self->g_run_error('Perl Stack Overflow');
            }
            elsif (
                $self->num_perl_calls >= (
                    LuaLimits->LUAI_MAXCCALLS +
                      ( LuaLimits->LUAI_MAXCCALLS >> 3 )
                )
              )
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

    method d_pre_call (VM::StkId $func, Int $n_results) {
                        #if $func is a perl function, execute it and return true
                        #else prepare for Lua call, return false

        my $cl = Util->as( $func->value );
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
            $self->ci->func($func);
            $self->ci->base($stack_base);
            $self->ci->top( $stack_base + $p->max_stack_size );
            $self->ci->saved_pc(
                new VM::Pointer( list => $p->code, index => 0 ) );
            $self->ci->call_status( CallStatus->CIST_LUA );

            $self->top( $self->ci->top );

            return 0;    #false
        }

        my $pcl = Util->as( $func->value, 'VM::Object::PClosure' );
        if ( defined($pcl) ) {

            $self->ci( $self->extend_ci );
            $self->ci->num_results($n_results);
            $self->ci->func($func);
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

    method d_pos_call (VM::StkId $first_result) {
        my $ci     = $self->ci;          #VM::CallInfo
        my $res    = $ci->func;          #VM::StkId
        my $wanted = $ci->num_results;

        $self->ci( $ci->previous );
        my $i = $wanted;
        for ( ; $i != 0 && $first_result->index < $self->top->index ; --$i ) {
            $res->value_inc( $first_result->value_inc );
        }
        while ( $i-- > 0 ) {
            $res->value_inc( new VM::Object::Nil );
        }

        $self->top($res);
        return ( $wanted - LuaDef->LUA_MULTRET );
    }

    method extend_ci {
        my $ci = new VM::CallInfo;
        $self->ci->next($ci);
        $ci->previous( $self->ci );
        $ci->next(undef);
        return $ci;
    }

    method adjust_varargs {
        die "#TODO";
    }

    method try_func_tm {
        die "#TODO";
    }

    #end of DO part

    #AuxLib part
    has 'free_list' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );
    has 'LEVELS1' => (    # size of the first part of the stack
        is      => 'rw',
        isa     => 'Int',
        default => 12,
    );
    has 'LEVELS2' => (    # size of the second part of the stack
        is      => 'rw',
        isa     => 'Int',
        default => 10,
    );

    method l_where {
        die "#TODO";
    }

    method l_error {
        die "#TODO";
    }

    method l_check_any {
        die "#TODO";
    }

    method l_check_number {
        die "#TODO";
    }

    method l_check_integer {
        die "#TODO";
    }

    method l_check_string {
        die "#TODO";
    }

    method l_check_unsigned {
        die "#TODO";
    }

    method l_opt {
        die "#TODO";
    }

    method l_opt_int {
        die "#TODO";
    }

    method l_opt_string {
        die "#TODO";
    }

    method type_error {
        die "#TODO";
    }

    method tag_error {
        die "#TODO";
    }

    method l_check_type {
        die "#TODO";
    }

    method l_arg_check {
        die "#TODO";
    }

    method l_arg_error {
        die "#TODO";
    }

    method l_type_name {
        die "#TODO";
    }

    method l_get_meta_field {
        die "#TODO";
    }

    method l_call_meta {
        die "#TODO";
    }

    method push_func_name {
        die "#TODO";
    }

    method count_levels {
        die "#TODO";
    }

    method l_trace_back {
        die "#TODO";
    }

    method l_len {
        die "#TODO";
    }

    method l_load_buffer {
        die "#TODO";
    }

    method l_load_buffer_x {
        die "#TODO";
    }

    method l_load_bytes ($bytes, Str $name) {
        my $load_info = new VM::BytesLoadInfo( bytes => $bytes );
        return $self->load( $load_info, $name, undef );
    }

    method err_file {
        return ThreadStatus->LUA_ERRFILE;
    }

    method l_load_file (Str $filename) {
        return $self->l_load_file_x( $filename, undef );
    }

    method l_load_file_x (Str|Undef $filename, Str|Undef $mode ) {
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

    method l_load_string {
        die "#TODO";
    }

    method l_do_string {
        die "#TODO";
    }

    method l_do_file (Str $file_name) {
        my $status = $self->l_load_file($file_name);
        if ( $status != ThreadStatus->LUA_OK ) {
            return $status;
        }
        return $self->api->p_call( 0, LuaDef->LUA_MULTRET, 0 );
    }

    method l_gsub {
        die "#TODO";
    }

    method l_to_string {
        die "#TODO";
    }

    method l_open_libs {
        die "#TODO";
    }

    method l_require_f {
        die "#TODO";
    }

    method l_get_sub_table {
        die "#TODO";
    }

    method l_new_lib_table {
        die "#TODO";
    }

    method l_new_lib {
        die "#TODO";
    }

=item l_set_funcs
Registers all functions in the array l (see luaL_Reg) into the table on 
the top of the stack (below optional upvalues, see next).

When nup is not zero, all functions are created sharing nup upvalues, 
which must be previously pushed on the stack on top of the library table. 
These values are popped from the stack after the registration.

=cut

    method l_set_funcs ( ArrayRef [Common::NameFuncPair] $define, Int $nup) {
        for my $pair (@$define) {
            for ( 1 .. $nup ) {
                $self->api->push_value( -$nup );
            }
            $self->api->push_perl_closure( $pair->func, $nup );
            $self->api->set_field( -( $nup + 2 ), $pair->name );
        }
        $self->api->pop($nup);
    }

    method find_field {
        die "#TODO";
    }

    method push_global_func_name {
        die "#TODO";
    }

    method l_ref {
        die "#TODO";
    }

    method l_unref {
        die "#TODO";
    }

    #end of AuxLib part

    #Func part
    method f_find_upval (VM::StkId $level) {
        die "#TODO";

        #my $node = $self->open_upval->[0];
        #my $prev = Undef;

        #while(defined($node)){
        #my $upval
        #}
    }

    method f_close (VM::StkId $level) {
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

    method f_get_local_name (VM::Object::Proto $proto, Int $local_number, Int $pc) {
        die "#TODO";
    }

    #end of Func part

    #VM part

    method v_execute {
        die "#TODO";
        my $env;       #VM::ExecuteEnvironment
        my $ci = $self->ci;
      newframe:
        my $cl = Util->as( $ci->func->value, 'VM::Object::LClosure' );
        $env->k( new VM::StkId( list => $cl->proto->k, index => 0 ) );
        $env->base( $ci->base );

        while (1) {
            my $i = $ci->saved_pc->value_inc;    #VM::Instruction
            $env->i($i);
            my $ra = $env->RA;
            $self->dump_stack( $env->base->index );

            given ( $i->GET_OPCODE() ) {
                when ( Opcode->OP_MOVE . '' ) {
                    my $rb = $env->RB;
                    $ra->value( $rb->value );
                    break;
                }
                when ( Opcode->OP_LOADK . '' ) {
                    my $rb = $env->k + $i->GETARG_Bx();    #VM::StkId
                    $ra->value( $rb->value );
                    break;
                }
                when ( Opcode->OP_LOADKX . '' )   { die "#TODO"; }
                when ( Opcode->OP_LOADBOOL . '' ) { die "#TODO"; }
                when ( Opcode->OP_LOADNIL . '' )  { die "#TODO"; }
                when ( Opcode->OP_GETUPVAL . '' ) { die "#TODO"; }
                when ( Opcode->OP_GETTABUP . '' ) { die "#TODO"; }
                when ( Opcode->OP_GETTABLE . '' ) { die "#TODO"; }
                when ( Opcode->OP_SETTABUP . '' ) { die "#TODO"; }
                when ( Opcode->OP_SETUPVAL . '' ) { die "#TODO"; }
                when ( Opcode->OP_SETTABLE . '' ) { die "#TODO"; }
                when ( Opcode->OP_NEWTABLE . '' ) { die "#TODO"; }
                when ( Opcode->OP_SELF . '' )     { die "#TODO"; }
                when ( Opcode->OP_ADD . '' )      { die "#TODO"; }
                when ( Opcode->OP_SUB . '' )      { die "#TODO"; }
                when ( Opcode->OP_MUL . '' )      { die "#TODO"; }
                when ( Opcode->OP_DIV . '' )      { die "#TODO"; }
                when ( Opcode->OP_MOD . '' )      { die "#TODO"; }
                when ( Opcode->OP_POW . '' )      { die "#TODO"; }
                when ( Opcode->OP_UNM . '' )      { die "#TODO"; }
                when ( Opcode->OP_NOT . '' )      { die "#TODO"; }
                when ( Opcode->OP_LEN . '' )      { die "#TODO"; }
                when ( Opcode->OP_CONCAT . '' )   { die "#TODO"; }
                when ( Opcode->OP_JMP . '' )      { die "#TODO"; }
                when ( Opcode->OP_EQ . '' )       { die "#TODO"; }
                when ( Opcode->OP_LT . '' )       { die "#TODO"; }
                when ( Opcode->OP_LE . '' )       { die "#TODO"; }
                when ( Opcode->OP_TEST . '' )     { die "#TODO"; }
                when ( Opcode->OP_TESTSET . '' )  { die "#TODO"; }
                when ( Opcode->OP_CALL . '' )     { die "#TODO"; }
                when ( Opcode->OP_TAILCALL . '' ) { die "#TODO"; }
                when ( Opcode->OP_RETURN . '' )   { die "#TODO"; }
                when ( Opcode->OP_FORLOOP . '' )  { die "#TODO"; }
                when ( Opcode->OP_FORPREP . '' )  { die "#TODO"; }
                when ( Opcode->OP_TFORCALL . '' ) { die "#TODO"; }
                when ( Opcode->OP_TFORLOOP . '' ) { die "#TODO"; }
                when ( Opcode->OP_SETLIST . '' )  { die "#TODO"; }
                when ( Opcode->OP_CLOSURE . '' )  { die "#TODO"; }
                when ( Opcode->OP_VARARG . '' )   { die "#TODO"; }
                when ( Opcode->OP_EXTRAARG . '' ) { die "#TODO"; }
                default                           { die "#TODO"; }
            }
        }

    }

    method v_not_implemented {
        die "#TODO";
    }

    method fast_tm (VM::Object::Table $et, Int $tm) {    #$tm=>TMS
        if ( !defined($et) ) {
            return undef;
        }

        if ( ( $et->flags & ( 1 << $tm ) ) != 0 ) {
            return undef;
        }

        return $self->t_get_tm( $et, $tm );
    }

    method v_get_table (VM::Object $t, VM::Object $key, VM::StkId $val) {
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

    method v_set_table (VM::Object $t, VM::Object $key, VM::StkId $val) {
        for ( 1 .. LuaConf->MAXTAGLOOP ) {
            my $tm_obj;    #VM::Object
            my $tbl = Util->( $t, "VM::Object::Table" );
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

    method v_push_closure {
        die "#TODO";
    }

    method v_obj_len {
        die "#TODO";
    }

    method v_concat {
        die "#TODO";
    }

    method v_do_jump {
        die "#TODO";
    }

    method v_do_next_jump {
        die "#TODO";
    }

    method v_to_number {
        die "#TODO";
    }

    method tms2op (Int $op) {            #$op=>TMS
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

    method call_tm ( VM::Object $f, VM::Object $p1, VM::Object $p2, VM::StkId $p3, Bool $has_res) {
        my $func = $self->top;
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

    method call_bin_tm (VM::StkId $p1, VM::StkId $p2, VM::StkId $res, Int $tm) { #$tm=>TMS
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

    method v_arith (VM::StkId $ra, VM::StkId $rb, VM::StkId $rc, Int $op) { #$op=>TMS

        my $b = $self->v_to_number( $rb->value );
        my $c = $self->v_to_number( $rc->value );
        if ( defined($b) && defined($c) ) {
            my $res =
              $self->o_arith( $self->tms2op($op), $b->value, $c->value );
            $ra->value( new VM::Object::Number( value => $res ) );
        }
        elsif ( !$self->call_bin_tm( $rb, $rc, $ra, $op ) ) {
            $self->g_arith_error( $rb, $rc );
        }
    }

    method call_order_tm {
        die "#TODO";
    }

    method v_less_than {
        die "#TODO";
    }

    method v_less_equal {
        die "#TODO";
    }

    method v_finish_op {
        die "#TODO";
    }

    method v_raw_equal_obj {
        die "#TODO";
    }

    method equal_obj {
        die "#TODO";
    }

    method get_equal_tm {
        die "#TODO";
    }

    method v_equal_object {
        die "#TODO";
    }

    #end of VM part

    #TagMethod part
    method get_tag_method_name (Int $tm) {    #$tm=>TMS
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

    method t_get_tm (VM::Object::Table $mt, Int $tm) {    #$tm=>TMS
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

    method t_get_tm_by_obj (VM::Object $o, Int $tm) {        #$tm=>TMS
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
                $mt = $self->g->metatables->[ $o->type ];
                break;
            }
        }
        return defined($mt)
          ? $mt->get_str( $self->get_tag_method_name($tm) )
          : VM::Object::Nil->new;
    }

    #end of TagMethod part

    #Debug part
    method get_stack {    #LuaAPI
        die "#TODO";
    }

    method get_info {
        die "#TODO";
    }

    method aux_get_info {
        die "#TODO";
    }

    method collect_valid_lines {
        die "#TODO";
    }

    method get_func_name {
        die "#TODO";
    }

    method func_info {
        die "#TODO";
    }

    method add_info (Str $msg) {
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

    method g_run_error (Str $msg) {
        $self->add_info($msg);
        $self->g_error_msg();
    }

    method g_error_msg {
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

    method upval_name {
        die "#TODO";

    }

    method get_upvalue_name {
        die "#TODO";

    }

    method k_name {
        die "#TODO";

    }

    method find_set_reg {
        die "#TODO";
    }

    method get_obj_name {
        die "#TODO";
    }

    method is_in_stack {
        die "#TODO";
    }

    method g_simple_type_error (VM::Object $o, Str $op) {
        my $t = $self->obj_type_name($o);
        $self->g_run_error("attempt to {$op} a {$t} value");
    }

    method g_type_error {
        die "#TODO";
    }

    method g_arith_error {
        die "#TODO";
    }

    method g_order_error {
        die "#TODO";
    }

    method g_concate_error {
        die "#TODO";
    }

    #end of Debug part
}

