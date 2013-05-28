# t/17-vm-runtime_exception.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
use Test::More;
use_ok 'VM::RuntimeException';
use_ok 'VM::Common::ThreadStatus';

my $e =
  VM::RuntimeException->new( err_code => VM::Common::ThreadStatus->LUA_ERRERR );

isa_ok $e, 'VM::RuntimeException';

eval { die $e };

isa_ok $@, 'VM::RuntimeException';

is $@->err_code, VM::Common::ThreadStatus->LUA_ERRERR, 'error code ok';

done_testing;
