require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/arithmetic_evaluator'
require File.dirname(__FILE__) + '/arithmetic_test_methods'
eval(Dhaka::Parser.new(ArithmeticGrammar).compile_to_ruby_source_as(:CompiledArithmeticParser))

class TestArithmeticEvaluator < Test::Unit::TestCase
  include ArithmeticTestMethods
  
  def setup
    @min_func = Proc.new {|args| args.inject {|min, elem| min = (elem < min ? elem : min)}}
    @max_func = Proc.new {|args| args.inject {|max, elem| max = (elem > max ? elem : max)}}
  end

  def test_results_simple_arithmetic_given_tokens_and_parse_tree_1
    token_stream = [token('n', 2), token('-', nil), token('n', 4), token(Dhaka::END_SYMBOL_NAME, nil)]
    parse_tree   = parse(token_stream)
    assert_equal -2, ArithmeticEvaluator.new(@min_func, @max_func).evaluate(parse_tree)
  end

  def test_results_simple_arithmetic_given_tokens_and_parse_tree_2
    token_stream = [token('n', 2), token('-', nil), token('(', nil), token('n', 3), token('/', nil), token('n', 4), token(')', nil), token(Dhaka::END_SYMBOL_NAME, nil)]
    parse_tree   = parse(token_stream)
    assert_equal 1.25, ArithmeticEvaluator.new(@min_func, @max_func).evaluate(parse_tree)
  end

  def test_results_simple_arithmetic_given_tokens_and_parse_tree_3
    token_stream = [token('n', 2), token('+', nil), token('(', nil), token('n', 3), token('/', nil), token('(', nil), token('n', 7), token('-', nil), token('n', 5), token(')', nil) , token(')', nil), token(Dhaka::END_SYMBOL_NAME, nil)]
    parse_tree   = parse(token_stream)
    assert_equal 3.5, ArithmeticEvaluator.new(@min_func, @max_func).evaluate(parse_tree)
  end

  def test_results_simple_arithmetic_given_tokens_and_parse_tree_4
    token_stream = [token('n', 2), token('+', nil), token('h', nil), token('(', nil), token('n', 3), token(',', nil), token('n', 4), token(')', nil), token(Dhaka::END_SYMBOL_NAME, nil)]
    parse_tree   = parse(token_stream)
    assert_equal 6, ArithmeticEvaluator.new(@min_func, @max_func).evaluate(parse_tree)
  end

  def test_results_simple_arithmetic_given_tokens_and_parse_tree_5
    token_stream = [token('n', 2), token('+', nil), token('l', nil), token('(', nil), token('n', 3), token(',', nil), token('n', 4), token(')', nil), token(Dhaka::END_SYMBOL_NAME, nil)]
    parse_tree   = parse(token_stream)
    assert_equal 5, ArithmeticEvaluator.new(@min_func, @max_func).evaluate(parse_tree)
  end
end