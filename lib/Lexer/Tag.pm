# lib/Lexer/Tag.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class Lexer::Tag {

    use MooseX::ClassAttribute;

    my @name = qw(
      AND  BREAK
      DO ELSE ELSEIF END FALSE FOR FUNCTION
      IF IN LOCAL NIL NOT OR REPEAT
      RETURN THEN TRUE UNTIL WHILE

      CONCAT DOTS EQ GE LE NE NUMBER
      NAME STRING EOS
    );
    my $first_reserved = 257;
    for (@name) {
        class_has $_ => (
            is      => 'ro',
            isa     => 'Int',
            default => $first_reserved++
        );
    }
}

1;

