# t/20-vm-undump.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use VM::BinaryBytesReader;
use VM::File;
use_ok 'VM::Undump';

my $undump = new VM::Undump(
    reader => new VM::BinaryBytesReader(
        load_info => VM::File->open_file("t_files/5.2/num.bin")
    )
);
isa_ok $undump, 'VM::Undump';

$undump->load_header;
my $proto = $undump->load_function;
isa_ok $proto, 'VM::Object::Proto';

$undump = new VM::Undump(
    reader => new VM::BinaryBytesReader(
        load_info => VM::File->open_file("t_files/5.2/hello_fun.bin")
    )
);

$undump->load_header;
$proto = $undump->load_function;

isa_ok $proto, 'VM::Object::Proto';

isa_ok VM::Undump->load_binary( '',
    VM::File->open_file("t_files/5.2/hello_fun.bin"), '' ),
  'VM::Object::Proto';

done_testing;
