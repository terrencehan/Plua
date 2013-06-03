# lib/VM/GlobalState.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::GlobalState {
    use lib '../';

    #-BUILD (state => VM::State)
    use VM::Object::Table;
    use VM::Object::Upvalue;
    use VM::State;
    use aliased 'VM::Common::LuaType';

    has 'registy' => (
        is      => 'rw',
        isa     => 'VM::Object::Table',
        default => sub { new VM::Object::Table; },
    );

    has 'upval_head' => (
        is      => 'rw',
        isa     => 'VM::Object::Upvalue',
        default => sub { new VM::Object::Upvalue; },
    );

    has 'meta_tables' => (
        is      => 'rw',
        isa     => 'ArrayRef[VM::Object::Table]',
        default => sub { [] },
    );

    has 'man_thread' => (
        is  => 'rw',
        isa => 'VM::State',
    );

    method BUILD ($args) {
        $self->man_thread( $args->{state} );
    }

}

1;
