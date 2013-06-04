# lib/VM/Undump.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use v5.10;

package VM::Undump;

use lib '../';
use plua;
use VM::BinaryBytesReader;
use VM::Instruction;
use VM::Object::Nil;
use VM::Object::Proto;
use VM::Object::Boolean;
use VM::Object::Number;
use VM::Object::String;
use VM::Object::UpvalDesc;
use VM::Object::LocVar;
use aliased 'VM::Common::ThreadStatus';
use aliased 'VM::Common::LuaType';

#-BUILD (reader => VM::BinaryBytesReader)

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'reader',    #VM::BinaryBytesReader
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

sub load_binary {
    my ($self) = @_;
    my (
        $class,
        $lua,          #VM::State
        $load_info,    #LoadInfo
        $name,         #Str
    ) = @_;
    my $ret = eval {
        my $reader = new VM::BinaryBytesReader( load_info => $load_info );
        my $undump = new VM::Undump( reader => $reader );
        $undump->load_header();
        return $undump->load_function();
    };
    if ($@) {
        $lua->o_push_string("{$name}: {$@} precompiled chunk");
        $lua->d_throw( ThreadStatus->LUA_ERRSYNTAX );
    }
    else {
        return $ret;
    }
}

sub load_int {
    my ($self) = @_;
    return $self->reader->read_int;
}

sub load_byte {
    my ($self) = @_;
    return $self->reader->read_byte;
}

sub load_bytes {
    my ( $self, $count ) = @_;
    return $self->reader->read_bytes($count);
}

sub load_string {
    my ($self) = @_;
    return $self->reader->read_string;
}

sub load_boolean {
    my ($self) = @_;
    return $self->load_byte != 0;
}

sub load_number {
    my ($self) = @_;
    return $self->reader->read_double;
}

sub load_header {
    my ($self) = @_;
    return $self->load_bytes( 4 + 8 + 6 );
}

sub load_instruction {
    my ($self) = @_;
    return new VM::Instruction( value => $self->reader->read_uint );
}

sub load_function {
    my ($self) = @_;
    my $proto = new VM::Object::Proto(
        line_defined      => $self->load_int,
        last_line_defined => $self->load_int,
        num_params        => $self->load_byte,
        is_vararg         => $self->load_boolean,
        max_stack_size    => $self->load_byte,
    );

    $self->load_code($proto);
    $self->load_constants($proto);
    $self->load_upvalues($proto);
    $self->load_debug($proto);
    return $proto;
}

sub load_code {
    my ( $self, $proto ) = @_;
    my $n = $self->load_int;
    $proto->code( [] );
    for ( 1 .. $n ) {
        push $proto->code, $self->load_instruction;
    }
}

sub load_constants {
    my ( $self, $proto ) = @_;
    my $n = $self->load_int;
    $proto->k( [] );
    for ( 1 .. $n ) {
        my $t = $self->load_byte;
        given ($t) {
            when ( LuaType->LUA_TNIL . '' ) {
                push $proto->k, new VM::Object::Nil;
                break;
            }

            when ( LuaType->LUA_TBOOLEAN . '' ) {
                push $proto->k,
                  new VM::Object::Boolean( value => $self->load_boolean );
                break;
            }

            when ( LuaType->LUA_TNUMBER . '' ) {
                push $proto->k,
                  new VM::Object::Number( value => $self->load_number );
                break;
            }
            when ( LuaType->LUA_TSTRING . '' ) {
                push $proto->k,
                  new VM::Object::String( value => $self->load_string );
                break;
            }
            default {
                die "LoadConstants unknown type: $t ";
            }
        }
    }
    $n = $self->load_int;
    $proto->p( [] );
    for ( 1 .. $n ) {
        push $proto->p, $self->load_function;
    }
}

sub load_upvalues {
    my ( $self, $proto ) = @_;
    my $n = $self->load_int;

    $proto->upvalues( [] );
    for ( 1 .. $n ) {
        push $proto->upvalues,
          new VM::Object::UpvalDesc(
            name     => undef,
            in_stack => $self->load_boolean,
            index    => $self->load_byte,
          );
    }
}

sub load_debug {
    my ( $self, $proto ) = @_;
    $proto->source( $self->load_string );

    #line info
    my $n = $self->load_int;
    $proto->line_info( [] );
    for ( 1 .. $n ) {
        push $proto->line_info, $self->load_int;
    }

    #LocalVar
    $n = $self->load_int;
    $proto->loc_vars( [] );
    for ( 1 .. $n ) {
        push $proto->loc_vars,
          new VM::Object::LocVar(
            var_name => $self->load_string,
            start_pc => $self->load_int,
            end_pc   => $self->load_int,
          );
    }

    #upvalues' name
    $n = $self->load_int;
    for ( 1 .. $n ) {
        $proto->upvalues->[ $_ - 1 ]->name( $self->load_string );
    }
}

1;
