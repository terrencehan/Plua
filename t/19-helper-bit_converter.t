# t/19-helper-bit_converter.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use_ok 'Helper::BitConverter';

my @bytes = ( 0x9A, 0x99, 0x99, 0x99, 0x99, 0x99, 0x15, 0x40 );

is Helper::BitConverter->to_double(@bytes), 5.4;

@bytes = ( 0x0f, 0x00, 0x00, 0x00 );
is Helper::BitConverter->to_int32(@bytes),  15;
is Helper::BitConverter->to_uint32(@bytes), 15;

@bytes = ( 0x00, 0x00, 0x00, 0x80 );
is Helper::BitConverter->to_int32(@bytes),  -2**31;
is Helper::BitConverter->to_uint32(@bytes), 2**31;

done_testing;
