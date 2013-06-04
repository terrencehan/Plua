# lib/VM/Object/LocVar.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Object::LocVar;

sub new {
    my ( $class, @args ) = @_;
    bless {@args}, $class;
}

BEGIN {
    my $class = __PACKAGE__;
    for my $func_name ( 'var_name', 'start_pc', 'end_pc' ) {
        *t = eval { "*" . $class . "::" . $func_name };
        *t = sub {
            my ( $self, $val ) = @_;
            if ( defined $val ) {
                return $self->{$func_name} = $val;
            }
            else {
                if ( !defined $self->{$func_name} ) {
                    return undef;
                }
                else {
                    return $self->{$func_name};
                }
            }
        };
    }
}

1;
