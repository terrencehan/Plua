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
    use aliased 'VM::Common::LuaType';
    use aliased 'VM::Common::LuaOp';
    use aliased 'VM::Common::LuaDef';
    use aliased 'VM::Common::LuaConf';
    use aliased 'VM::Common::ThreadStatus';

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

    #API part:
    method new_thread {          #LuaAPI
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
            my $cl = ( $self->top - 1 )->value;    #VM::Object::LClosure;
            if ( scalar @{ $cl->upvals } == 1
                && ref($cl) eq 'VM::Object::LClosure' )
            {
                $cl->upvals->[0]->v->value(
                    $self->g->registy->get_int( LuaDef->LUA_RIDX_GLOBALS ) );
            }
        }

        return $status;
    }

    method dump {                                     #LuaAPI

        die "#TODO";
    }

    method get_context {                              #LuaAPI

        die "#TODO";

    }

    method call (Int $num_args, Int $num_results) {    #LuaAPI
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

    method check_results {
        die "#TODO";
    }

    method p_call (Int $num_args, Int $num_results, Int $err_func) {    #LuaAPI
        die "#TODO";
    }

    method p_call_k (Int $num_args, Int $num_results, Int $err_func, Int $context, CodeRef $continue_func) { #LuaAPI
        die "#TODO";
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

        my $tbl = $addr->value;
        Util->api_check( defined($tbl) && ref($tbl) eq 'VM::Object::Table',
            "table expected" );
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

    method get_field {                        #LuaAPI
        die "#TODO";
    }

    method set_field (Int $index, Str $key) {    #LuaAPI
        #my_path:1
        my $addr;      #VM::StkId
        if ( !$self->index2addr( $index, \$addr ) ) {
            Util->invalid_index();
        }
        $self->top->value_inc( new VM::Object::String( value => $key ) );
        $self->v_set_table( #my_path:2
            $addr->value,
            ( $self->top - 1 )->value,
            $self->top - 2
        );
        $self->top( $self->top + 2 );
    }

    method concat {    #LuaAPI
        die "#TODO";
    }

    method get_type { #name conflict with attr "type"                            #LuaAPI
        die "#TODO";
    }

    method type_name {    #LuaAPI
        die "#TODO";
    }

    method obj_type_name {
        die "#TODO";
    }

    method o_push_string {
        die "#TODO";
    }

    method is_nil {           #LuaAPI
        die "#TODO";
    }

    method is_none {          #LuaAPI
        die "#TODO";
    }

    method is_none_or_nil {    #LuaAPI
        die "#TODO";
    }

    method is_string {         #LuaAPI
        die "#TODO";
    }

    method is_table {          #LuaAPI
        die "#TODO";
    }

    method is_function {       #LuaAPI
        die "#TODO";
    }

    method compare {           #LuaAPI
        die "#TODO";
    }

    method raw_equal {         #LuaAPI
        die "#TODO";
    }

    method raw_len {           #LuaAPI
        die "#TODO";
    }

    method len {               #LuaAPI
        die "#TODO";
    }

    method push_nil {          #LuaAPI
        $self->top->value( new VM::Object::Nil );
        $self->api_incr_top;
    }

    method push_boolean {      #LuaAPI
        die "#TODO";
    }

    method push_number {       #LuaAPI
        die "#TODO";
    }

    method push_integer {      #LuaAPI
        die "#TODO";
    }

    method push_unsigned {     #LuaAPI
        die "#TODO";
    }

    method push_string (Str $s) {       #LuaAPI
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

    method push_perl_function {    #LuaAPI
        die "#TODO";
    }

    method push_perl_closure {     #LuaAPI
        die "#TODO";
    }

    method push_value {            #LuaAPI
        die "#TODO";
    }

    method push_global_table {     #LuaAPI
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
        my $s = $addr->value;
        if ( ref($s) eq 'VM::Object::String' ) {
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
    method d_throw {
        die "#TODO";
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

    method d_call {
        die "#TODO";
    }

    method d_pre_call {
        die "#TODO";
    }

    method d_pos_call {
        die "#TODO";
    }

    method extend_ci {
        die "#TODO";
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

    method l_set_funcs {
        die "#TODO";
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

    has 'MAXTAGLOOP' => (
        is      => 'ro',
        isa     => 'Int',
        default => 100,
    );

    method v_execute {
        die "#TODO";
    }

    method v_not_implemented {
        die "#TODO";
    }

    method fast_tm {
        die "#TODO";
    }

    method v_get_table {
        die "#TODO";
    }

    method v_set_table {#my_path:3
        die "#TODO";
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

    method tms2op {
        die "#TODO";
    }

    method call_tm {
        die "#TODO";
    }

    method call_bin_tm {
        die "#TODO";
    }

    method v_arith {
        die "#TODO";
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
}

1;
