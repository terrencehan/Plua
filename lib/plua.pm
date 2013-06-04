package plua;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(attr);

=item attr


=cut

sub attr {
    my ( $class, $default, @func_names ) = @_;
    for my $func_name (@func_names) {
        *t = eval { "*" . $class . "::" . $func_name };
        *t = sub {
            my ( $self, $val ) = @_;
            if ( defined $val ) {
                return $self->{$func_name} = $val;
            }
            else {
                if ( !defined $self->{$func_name} ) {
                    return $self->{$func_name} = $default;
                }
                else {
                    return $self->{$func_name};
                }
            }
        };
    }
}

1;
