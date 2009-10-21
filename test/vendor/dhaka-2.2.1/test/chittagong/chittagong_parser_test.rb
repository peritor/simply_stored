require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/chittagong_grammar'
begin
  require File.dirname(__FILE__) + "/chittagong_parser"
rescue LoadError
  puts "Please run the rake command in the root folder to generate the lexer and parser required for this test."
  exit
end

class TestChittagongParser < Test::Unit::TestCase

  def test_parses_a_series_of_statements
    token_stream = build_tokens(
      'newline',
      'word_literal', '=', 'numeric_literal', 'newline',
      'print', 'word_literal', 'newline',
      'newline',
      'word_literal', '=', 'word_literal', 'newline',
      'newline', Dhaka::END_SYMBOL_NAME
    )
    
    result = ChittagongParser.parse(token_stream)
    
    assert_equal(["single_term",
     "some_terms",
     "variable_name",
     "literal",
     "assignment_statement",
     "main_body_simple_statement",
     "single_main_body_statement",
     "single_term",
     "variable_name",
     "variable_reference",
     "print_statement",
     "main_body_simple_statement",
     "multiple_main_body_statements",
     "single_term",
     "multiple_terms",
     "variable_name",
     "variable_name",
     "variable_reference",
     "assignment_statement",
     "main_body_simple_statement",
     "multiple_main_body_statements",
     "single_term",
     "multiple_terms",
     "some_terms",
     "program"], result.linearize.collect {|node| node.production.name})
     
  end

  def build_tokens *symbol_names
    symbol_names.collect {|symbol_name| Dhaka::Token.new(symbol_name, nil, nil)}
  end
end 