# lib/VM/FileLoadInfo.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use MooseX::Declare;

class VM::FileLoadInfo extends VM::LoadInfo {

    #-BUILD (bytes => bytes)
    has 'bytes' => (    #isa bytes_array
        is      => 'rw',
        isa     => 'ArrayRef',
        default => sub { [] },
    );
    has 'pos' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    method read_byte {
    }

    method peek_byte {
    }
}

1;
