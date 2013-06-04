# lib/VM/Util.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com
use v5.10;

package VM::Util;
use Class::ISA;

sub assert {
    my ( $class, $condition, $message, $detail_message ) = @_;
    if ( !$condition ) {
        die( $message or "" ) . ( $detail_message or "" );
    }
}

sub api_check {
    my ( $class, $condition, $message ) = @_;
    assert( $class, $condition, $message );
}

sub strX2number {
    my (
        $class,
        $s,         #Str
        $curpos,    #ScalarRef[Int]
    ) = @_;

    my $pos = $$curpos;
    my @s_arr = split //, $s;
    while ( $pos < length($s) && $s_arr[$pos] =~ /\s/ ) {
        $pos++;
    }
    my $negative = is_negative( $s, \$pos );

    #check `ox'
    if ( $pos >= length($s)
        || !( $s_arr[$pos] eq '0' && $s_arr[ $pos + 1 ] =~ /[xX]/ ) )
    {
        return 0.0;
    }

    $pos += 2;    #skip `0x';

    my $r = 0.0;
    my $i = 0;
    my $e = 0;
    $r = read_hexa( $s, \$pos, $r, \$i );
    if ( $pos < length($s) && $s_arr[$pos] eq '.' ) {
        $pos++;    #skip `.'
        $r = read_hexa( $s, \$pos, $r, \$e );
    }
    if ( $i == 0 && $e == 0 ) {
        return 0.0;
    }

    # each fractional digit divides value by 2^-4
    $e *= -4;
    $$curpos = $pos;

    #exponent part
    if ( $pos < length($s) && $s_arr[$pos] =~ /[pP]/ ) {
        $pos++;
        my $exp_negative = is_negative( $s, \$pos );
        if ( $pos >= length($s) || $s_arr[$pos] !~ /\d/ ) {
            goto 'ret';
        }

        my $exp1 = 0;
        while ( $pos < length($s) && $s_arr[$pos] =~ /\d/ ) {
            $exp1 = $exp1 * 10 + $s_arr[$pos];
            $pos++;
        }
        if ($exp_negative) {
            $exp1 = -$exp1;
        }
        $e += $exp1;
    }
    $$curpos = $pos;
  ret:
    if ($negative) {
        $r = -$r;
    }
    return $r * ( 2**$e );
}

sub str2number {
    my (
        $class,
        $s,         #Str
        $curpos,    #ScalarRef[Int]
    ) = @_;

    my $pos = $$curpos;
    my @s_arr = split //, $s;
    while ( $pos < length($s) && $s_arr[$pos] =~ /\s/ ) {
        $pos++;
    }
    my $negative = is_negative( $s, \$pos );
    my $r        = 0.0;
    my $i        = 0;
    my $f        = 0;
    $r = read_decimal( $s, \$pos, $r, \$i );
    if ( $pos < length($s) && $s_arr[$pos] eq '.' ) {
        $pos++;
        $r = read_decimal( $s, \$pos, $r, \$f );
    }

    if ( $i == 0 && $f == 0 ) {
        return 0.0;
    }

    $f       = -$f;
    $$curpos = $pos;

    my $e = 0.0;
    if ( $pos < length($s) && $s_arr[$pos] =~ /[eE]/ ) {
        $pos++;
        my $exp_negative = is_negative( $s, \$pos );
        if ( $pos >= length($s) || $s_arr[$pos] !~ /\d/ ) {
            goto 'ret';
        }

        my $n;
        $e = read_decimal( $s, \$pos, $e, \$n );
        if ($exp_negative) {
            $e = -$e;
        }
        $f += $e;
    }
    $$curpos = $pos;
  ret:
    if ($negative) {
        $r = -$r;
    }
    return $r * ( 10**$f );
}

sub read_decimal {    #private
    my (
        $s,           #Str
        $pos,         #ScalarRef[Int]
        $r,           #Num
        $count,       #ScalarRef[Int]
    ) = @_;
    $$count = 0;
    my @s_arr = split //, $s;
    while ( $$pos < length($s) && $s_arr[$$pos] =~ /\d/ ) {
        $r = ( $r * 10.0 ) + $s_arr[$$pos];
        $$pos++;
        $$count++;
    }
    return $r;
}

sub read_hexa {       #private
    my (
        $s,           #Str
        $pos,         #ScalarRef[Int]
        $r,           #Num
        $count,       #ScalarRef[Int]
    ) = @_;
    $$count = 0;
    my @s_arr = split //, $s;
    while ( $$pos < length($s) && $s_arr[$$pos] =~ /[\da-fA-F]/ ) {
        $r = ( $r * 16.0 ) + hex( $s_arr[$$pos] );
        $$pos++;
        $$count++;
    }
    return $r;
}

sub is_negative {     #private
    my (
        $s,           #Str
        $pos,         #ScalarRef[Int]
    ) = @_;

    my @s_arr = split //, $s;
    my $c = $s_arr[$$pos];

    if ( $c eq '-' ) {
        $$pos++;
        return 1;
    }
    elsif ( $c eq '+' ) {
        $$pos++;
    }
    return 0;
}

sub api_check_num_elems {
    my (
        $class,
        $lua,    #VM::State
        $n,      #Int
    ) = @_;

    assert(
        $class,
        $n < ( $lua->top->index - $lua->ci->func->index ),
        "not enough elems in the stack"
    );
}

sub invalid_index {
    my $class = shift;
    assert( $class, 0, "invalid index" );
}

sub as {
    my ( $class, $o, $class_name, ) = @_;
    if ( !defined($o) ) {
        return undef;
    }
    my @classes = Class::ISA::self_and_super_path( ref $o );
    return $class_name ~~ @classes ? $o : undef;
}

1;
