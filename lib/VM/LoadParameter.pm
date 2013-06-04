# lib/VM/LoadParameter.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::LoadParameter;

#-BUILD (load_info => VM::LoadInfo, name => Str, mode => Str)

sub new {
    my ( $class, @args ) = @_;
    tom_cat $class;
    bless {@args}, $class;
}

sub tom_cat {
    my $class = shift;
    for my $func_name (
        'load_info',    #VM::LoadInfo
        'name', 'mode', #Str
      )
    {
        *t = eval { "*" . $class . "::" . $func_name };
        *t = sub {
            my ( $self, $val ) = @_;
            if ( defined $val ) {
                return $self->{$func_name} = $val;
            }
            else {
                if ( !defined $self->{$func_name} ) {    #default
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
