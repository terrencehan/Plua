# lib/VM/Object.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class VM::Object {
    use VM::Type;

    for (
        qw/is_nil is_false is_function is_clousre is_string is_number is_table/)
    {
        has $_ => (
            is      => 'rw',
            isa     => 'Bool',
            default => 0,
        );
    }

    has 'type' => (
        is      => 'rw',
        isa     => 'Int',
        default => sub { VM::Type->LUA_TNONE }
    );

    method to_string  { }
    method to_literal { $self->to_string }
    method to_num     { return 0.0 }
}

1;
