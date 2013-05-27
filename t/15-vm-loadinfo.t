# t/15-vm-loadinfo.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';

use Test::More;

use_ok 'VM::StringLoadInfo';
use_ok 'VM::BytesLoadInfo';

my $s_load_info = new VM::StringLoadInfo( str => "hello" );

is $s_load_info->peek_byte(), 'h', 'peek_byte ok';
is $s_load_info->read_byte(), 'h', 'read_byte ok';
is $s_load_info->peek_byte(), 'e', 'peek_byte ok';
for(1..4){
    $s_load_info->read_byte();
}
is $s_load_info->pos, 5;
is $s_load_info->peek_byte(), -1, 'peek_byte ok';
is $s_load_info->read_byte(), -1, 'peek_byte ok';


my $bits = pack "C*", 0x0a, 0x0b, 0x0c, 0x0d;
my $b_load_info = new VM::BytesLoadInfo( bytes => $bits);

is $b_load_info->peek_byte(), 0x0a, 'b peek_byte ok';
is $b_load_info->read_byte(), 0x0a, 'b read_byte ok';
is $b_load_info->peek_byte(), 0x0b, 'b peek_byte ok';
for(1..3){
    $b_load_info->read_byte();
}
is $b_load_info->peek_byte(), -1, 'b peek_byte ok';
is $b_load_info->read_byte(), -1, 'b read_byte ok';
is $b_load_info->pos, 4;

done_testing;
