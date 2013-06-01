# lib/VM/Debug.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::Debug {

    use VM::CallInfo;
    has [ 'name', 'name_what', 'source', 'what', 'short_src', ] => (
        is  => 'rw',
        isa => 'Str',
    );

    has 'active_ci' => (
        is  => 'rw',
        isa => 'VM::CallInfo'
    );

    has [
        'current_line', 'num_ups',
        'num_params',   'line_defined',
        'last_line_defined',
      ] => (
        is  => 'rw',
        isa => 'Int'
      );

    has [ 'is_var_arg', 'is_tail_call', ] => (
        is  => 'rw',
        isa => 'Bool',
    );

}

1;
