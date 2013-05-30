# lib/VM/File.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::File {

    use VM::BytesLoadInfo;

    sub open_file {
        my (
            $class,
            $file_name,    #Str
        ) = @_;

        open my $in, "<", $file_name
          or die "an error occured when open $file_name";
        binmode $in;

        my @bytes = unpack "C*", do { local $/; <$in>; };
        return new VM::BytesLoadInfo( bytes => \@bytes )
          ;                #TODO temporily, VM::FileLoadInfo;
    }

    sub readable {
        my (
            $class,
            $file_name,    #Str
        ) = @_;
        return -r $file_name;
    }
}

1;
