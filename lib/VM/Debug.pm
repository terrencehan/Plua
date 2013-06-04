# lib/VM/Debug.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Debug;

use lib '../';
use VM::CallInfo;
use plua;

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, undef,
        'name', 'name_what', 'source', 'what', 'short_src',    #Str
        'active_ci',                                           #VM::CallInfo
        'current_line', 'num_ups', 'num_params', 'line_defined',    #Int
        'last_line_defined',                                        #Int
        'is_var_arg', 'is_tail_call',                               #Bool
    );
}

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

1;
