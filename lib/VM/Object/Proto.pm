# lib/VM/Object/Proto.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::Proto extends VM::Object {

    #-BUILD ()
    use lib '../../';
    use VM::Instruction;
    has code => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Instruction]',
        default => sub { [] },
    );
    has k => (    #constants used by the function
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object]',
        default => sub { [] },
    );
    has p => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object::Proto]',
        default => sub { [] },
    );
    has upvalues => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object::UpvalDesc]',
        default => sub { [] },
    );
    has [ 'linedefined', 'lastlinedefined', 'numparams', 'maxstacksize', ] => (
        is  => 'rw',
        isa => 'Int',
    );
    has is_vararg => (
        is  => 'rw',
        isa => 'Bool',
    );

    has source => (
        is  => 'rw',
        isa => 'Str',
    );
    has lineinfo => (
        is      => 'rw',
        isa     => 'ArrayRef[Int]',
        default => sub { [] },
    );

    has locvars => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object::LocVar]',
        default => sub { [] },
    );

    method BUILD {
        $self->type( VM::Common::LuaType->LUA_TPROTO );
    }

    method get_func_line( Int $pc) {
        return $pc < scalar $self->lineinfo ? $self->lineinfo->[$pc] : 0;
    };
}

1;
