use MooseX::Declare;

class VM::Object_ {
    for (
        qw/is_nil is_false is_function is_clousre is_string is_number is_table/)
    {
        has $_ => (
            is      => 'rw',
            isa     => 'Bool',
            default => 0,
        );
    }
}
