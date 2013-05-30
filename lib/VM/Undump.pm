# lib/VM/Undump.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;
use v5.10;

class VM::Undump {

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
    has 'reader' => (
        is       => 'rw',
        isa      => 'VM::BinaryBytesReader',
        required => 1,
    );

    sub load_binary {
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

    method load_int {
        return $self->reader->read_int;
    }

    method load_byte {
        return $self->reader->read_byte;
    }

    method load_bytes (Int $count) {
        return $self->reader->read_bytes($count);
    }

    method load_string {
        return $self->reader->read_string;
    }

    method load_boolean {
        return $self->load_byte != 0;
    }

    method load_number {
        return $self->reader->read_double;
    }

    method load_header {
        return $self->load_bytes( 4 + 8 + 6 );
    }

    method load_instruction {
        return new VM::Instruction( value => $self->reader->read_uint );
    }

    method load_function {
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

    method load_code ( VM::Object::Proto $proto) {
        my $n = $self->load_int;
        $proto->code( [] );
        for ( 1 .. $n ) {
            push $proto->code, $self->load_instruction;
        }
    }

    method load_constants (VM::Object::Proto $proto) {
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

    method load_upvalues (VM::Object::Proto $proto) {
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

    method load_debug (VM::Object::Proto $proto) {
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
}

1;
