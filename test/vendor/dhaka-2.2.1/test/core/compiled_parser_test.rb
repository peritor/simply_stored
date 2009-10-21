require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/simple_grammar"
eval(Dhaka::Parser.new(SimpleGrammar).compile_to_ruby_source_as(:SimpleParser))

class TestCompiledParser < Test::Unit::TestCase
  def test_compiled_parser_generates_parse_tree_for_simple_grammar
    parse_tree = SimpleParser.parse(build_tokens(%w| ( n - ( n - n ) ) - n # | +[Dhaka::END_SYMBOL_NAME]))
    assert_equal \
      ["literal",
       "term",
       "literal",
       "term",
       "literal",
       "subtraction",
       "parenthetized_expression",
       "subtraction",
       "parenthetized_expression",
       "term",
       "literal",
       "subtraction",
       "expression",
       "start"], parse_tree.linearize.collect {|node| node.production.name}
  end

  def test_parse_result_has_error_result_if_only_end_token_passed
    parse_result = SimpleParser.parse(build_tokens([Dhaka::END_SYMBOL_NAME]))
    assert parse_result.has_error?
  end
  
  def test_parse_result_is_nil_if_no_end_token
    parse_result = SimpleParser.parse(build_tokens(%w| n - n |))
    assert_nil(parse_result)
  end

  def test_parser_returns_error_result_with_index_of_bad_token_if_parse_error
    parse_result = SimpleParser.parse(build_tokens(['(', '-', ')', Dhaka::END_SYMBOL_NAME]))
    assert parse_result.has_error?
    assert_equal '-', parse_result.unexpected_token.symbol_name
  end

  def build_tokens(token_symbol_names)
    token_symbol_names.collect {|symbol_name| Dhaka::Token.new(symbol_name, nil, nil)}
  end
end
