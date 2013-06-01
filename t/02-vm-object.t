# t/02-vm-object.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
BEGIN { use_ok('VM::Object') }

my $o = VM::Object->new;

done_testing;
