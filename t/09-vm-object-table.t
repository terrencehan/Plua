# t/09-vm-object-table.t
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use strict;
use warnings;

use lib '../lib';
#use Test::More tests => 5;
use Test::More 'no_plan';
use VM::Type;
BEGIN { use_ok('VM::Object::Table') }

my $t = VM::Object::Table->new;
isa_ok $t, 'VM::Object::Table';
