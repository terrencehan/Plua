use strict;
use warnings;

use lib '../lib';
use Test::More tests => 1;
BEGIN { use_ok('VM::Object') };

my $o = VM::Object_->new;
