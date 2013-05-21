# lib/Lexer/Token.pm
# Copyright (c) 2013 terrencehan
# hanliang1990@gmail.com

use MooseX::Declare;

class Lexer::Token {

    #--BUILD (tag=>Num)
    has 'tag' => (
        is  => 'rw',
        isa => 'Num',
    );

    method to_string {
        chr $self->tag;
    }

}

1;
