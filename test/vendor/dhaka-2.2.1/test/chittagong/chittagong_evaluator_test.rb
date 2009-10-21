require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/chittagong_evaluator"
begin
  require File.dirname(__FILE__) + "/chittagong_parser"
rescue LoadError
  puts "Please run the rake command in the root folder to generate the lexer and parser required for this test."
  exit
end

class TestChittagongEvaluator < Test::Unit::TestCase
  def test_evaluates_a_simple_program
    token_stream  = build_tokens(
      ['newline'],
      ['word_literal', 'x'], ['='], ['numeric_literal', 23], ['newline'],
      ['print'], ['word_literal', 'x'], ['newline'],
      ['newline'],
      ['word_literal', 'y'], ['='], ['word_literal', 'x'], ['+'], ['word_literal', 'x'], ['newline'],
      ['print'], ['word_literal', 'y'], ['*'], ['word_literal', 'x'], ['newline'],
      ['if'], ['word_literal', 'x'], ['>'], ['word_literal', 'y'], ['newline'],
      ['print'], ['word_literal', 'x'], ['newline'],
      ['else'], ['newline'],
      ['print'], ['word_literal', 'y'], ['newline'],
      ['end'], ['newline'],
      ['newline'],
      [Dhaka::END_SYMBOL_NAME]
    )
    stack         = [{}]
    output_stream = []
    ChittagongEvaluator.new(stack, output_stream).evaluate(ChittagongParser.parse(token_stream))
    assert_equal(23, stack[0]['x'])
    assert_equal(46, stack[0]['y'])
    assert_equal(["23.0", "1058.0", "46.0"], output_stream)
  end
  
  def build_tokens *tokens
    tokens.collect {|token| Dhaka::Token.new(token[0], token[1], nil)}
  end
end