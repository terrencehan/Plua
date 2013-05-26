# lib/VM/Object/PClosure.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::PClosure with VM::Object::Closure extends VM::Object {

    #-BUILD (f => CodeRef)
    use VM::Common::ClosureType;
    use VM::Common::LuaType;
    has 'f' => (
        is  => 'rw',
        isa => 'CodeRef',
    );

    has 'upvals' => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object]',
        default => sub { [] },
    );

    method BUILD {
        $self->closure_type( VM::Common::ClosureType->PERL );
        $self->is_function(1);
        $self->is_clousre(1);
        $self->type( VM::Common::LuaType->LUA_TFUNCTION );
    }

    method get_upvalue ( Num $n, ScalarRef [VM::Object] $val ) {
        if ( !( 1 <= $n && $n <= scalar @$self->upvals ) ) {
            $$val = undef;
            return undef;
        }
        else {
            $$val = $self->upvals->[ $n - 1 ];
            return '';
        }
    }

    method set_upvalue ( Num $n, ScalarRef [VM::Object] $val ) {
        if ( !( 1 <= $n && $n <= scalar @$self->upvals ) ) {
            return undef;
        }
        else {
            $self->upvals->[ $n - 1 ]($val);
            return '';
        }
    }

}
1;
