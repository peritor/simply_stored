require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/arithmetic_precedence_grammar"
require File.dirname(__FILE__) + "/arithmetic_precedence_lexer_specification"
require File.dirname(__FILE__) + "/arithmetic_precedence_evaluator"

class TestArithmeticPrecedenceParser < Test::Unit::TestCase
  def test_parses_arithmetic_expressions
    fake_logger = FakeLogger.new
    parser      = Dhaka::Parser.new(ArithmeticPrecedenceGrammar, fake_logger)
    lexer       = Dhaka::Lexer.new(ArithmeticPrecedenceLexerSpecification)
    eval(parser.compile_to_ruby_source_as(:ArithmeticPrecedenceParser))
    eval(lexer.compile_to_ruby_source_as(:ArithmeticPrecedenceLexer))

    assert_equal(30, fake_logger.warnings.size)
    assert_equal(0, fake_logger.errors.size)
    
    assert_equal(-8, evaluate(parse("5 * -14/(2*7 - 7) + 2")))
    assert_equal(-4, evaluate(parse("-2^2")))
    assert_equal(10, evaluate(parse("2+2^3")))
    assert_equal(64, evaluate(parse("(2+2)^3")))
    assert_equal(128, evaluate(parse("(2+2)^3*2")))
    assert(parse("(2+2)^3^2").has_error?)
  end
  
  def parse(input)
    ArithmeticPrecedenceParser.parse(ArithmeticPrecedenceLexer.lex(input))
  end

  def evaluate(parse_tree)
    ArithmeticPrecedenceEvaluator.new.evaluate(parse_tree)
  end
end

