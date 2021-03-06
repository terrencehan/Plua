# lib/VM/Object/Proto.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::Proto;

use strict;
use warnings;

use lib '../../';
use plua;
use VM::Instruction;

use parent qw/VM::Object/;

#-BUILD ()

BEGIN {
    my $class = __PACKAGE__;
    attr(
        $class, [],
        'code',    #ArrayRef[VM::Instruction]
        'k',       #ArrayRef[VM::Object]
                   #constants used by the function

        'p',       #ArrayRef[VM::Object::Proto]
                   #functions defined inside the functions

        'upvalues',     #ArrayRef[VM::Object::UpvalDesc]

        'line_info',    #ArrayRef[Int]
                        #map from opcodes to source lines (debug information)
        'loc_vars',     #ArrayRef[VM::Object::LocVar]
    );
    attr(
        $class, undef,
        'line_defined', 'last_line_defined', 'num_params',    #Int
        'max_stack_size',                                     #Int
        'is_vararg',                                          #Bool
        'source',                                             #Str
    );
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;
    $self->type( VM::Common::LuaType->LUA_TPROTO );
    return $self;
}

sub get_func_line {
    my (
        $self,
        $pc,    #Int
    ) = @_;
    return $pc < scalar $self->line_info ? $self->line_info->[$pc] : 0;
}

1;
