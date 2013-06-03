# lib/VM/Object/LClosure.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object::LClosure with VM::Object::Closure extends VM::Object{
    use lib '../../';
    use VM::Common::ClosureType;
    use VM::Common::LuaType;

    #-BUILD (proto => VM::Object::Proto)
    method BUILD {
        $self->is_function(1);
        $self->is_clousre(1);
        $self->type( VM::Common::LuaType->LUA_TFUNCTION );
        $self->closure_type( VM::Common::ClosureType->LUA );
        for ( @{$self->proto->upvalues} ) {
            push $self->upvals, undef;
        }
    }

    has 'proto' => (
        is  => 'rw',
        isa => 'VM::Object::Proto',
    );

    has 'upvals' => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object::Upvalue]',
        default => sub { [] },
    );

    method get_upvalue ( Num $n, ScalarRef [VM::Object] $val ) {
        if ( !( 1 <= $n && $n <= scalar @{$self->upvals} ) ) {
            $$val = undef;
            return undef;
        }
        else {
            $$val = $self->upvals->[ $n - 1 ]->v->value;
            my $name = $self->proto->upvalues->[ $n- 1 ]->name;
            return ( defined $name ) ? $name : '';
        }
    }

    method set_upvalue ( Num $n, ScalarRef [VM::Object] $val ) {
        if ( !( 1 <= $n && $n <= scalar @{$self->upvals} ) ) {
            $$val = undef;
            return undef;
        }
        else {
            $self->upvals->[ $n - 1 ]->v->value($val);
            my $name = $self->proto->upvalues->[ $n- 1 ]->name;
            return ( defined $name ) ? $name : '';
        }
    }

}
1;
