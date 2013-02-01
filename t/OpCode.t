use strict;
use warnings;

use lib '../lib';
use Test::More tests => 1;
BEGIN { use_ok('VM::OpCode') };

my $opcode = VM::OpCode->new;
