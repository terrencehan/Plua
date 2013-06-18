# t/18-vm-binary_bytes_reader.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use VM::Common::LuaConf;
use VM::BytesLoadInfo;
use VM::File;
use_ok 'VM::BinaryBytesReader';

my $load_info = VM::File->open_file("t_files/5.1/num.bin");

my $reader = new VM::BinaryBytesReader( load_info => $load_info );

isa_ok $reader, 'VM::BinaryBytesReader';

$reader->read_bytes(4);

is $reader->read_byte, 0x51;

$reader->read_bytes( 0xc - 0x5 );

is $reader->read_string, "\@num.lua";

$reader->read_bytes( 0x35 - 0x18 );

is $reader->read_double, 5.4;

done_testing;
