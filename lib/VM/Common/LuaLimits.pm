# lib/VM/Common/LuaLimits.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

package VM::Common::LuaLimits;

my %h;

$h{MAX_INT}        = 0b01111111_11111111_11111111_11111111 - 2;    #TODO
$h{MAXUPVAL}       = 0b11111111;                                   #TODO
$h{LUAI_MAXCCALLS} = 200;
$h{MAXSTACK}       = 250;

for ( keys %h ) {
    *t = eval { "*" . __PACKAGE__ . "::" . $_ };
    my $res = $h{$_};
    *t = sub {
        $res;
    };
}

1;
