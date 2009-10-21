require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/chittagong_lexer_specification"
begin
  require File.dirname(__FILE__) + "/chittagong_lexer"
rescue LoadError
  puts "Please run the rake command in the root folder to generate the lexer and parser required for this test."
  exit
end

class TestChittagongLexer < Test::Unit::TestCase
  def test_tokenizes_a_program
    input = "
    x = 2 * 4
    y = 2 * x
    v = x == y
    if x > y
      print x
    else
      print y
    end
    "
    assert_equal(["newline",
     "word_literal",
     "=",
     "numeric_literal",
     "*",
     "numeric_literal",
     "newline",
     "word_literal",
     "=",
     "numeric_literal",
     "*",
     "word_literal",
     "newline",
     "word_literal",
     "=",
     "word_literal",
     "==",
     "word_literal",
     "newline",
     "if",
     "word_literal",
     ">",
     "word_literal",
     "newline",
     "print",
     "word_literal",
     "newline",
     "else",
     "newline",
     "print",
     "word_literal",
     "newline",
     "end",
     "newline",
     Dhaka::END_SYMBOL_NAME],  ChittagongLexer.lex(input).collect {|token| token.symbol_name})
  end
end