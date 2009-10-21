require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/bracket_grammar"
require File.dirname(__FILE__) + '/bracket_tokenizer'

class TestBracketGrammar < Test::Unit::TestCase
  def test_recognizes_faulty_bracket_configuration_correctly
    eval Dhaka::Parser.new(BracketGrammar).compile_to_ruby_source_as(:BracketParser)
    assert correct("[{(B)[B]}(B)]")
    assert correct("[[B]{(B)}(B)]")
    assert correct("{(B)[B]}")
    assert !correct("{B[B]}")
    assert !correct("B")
    assert !correct("[[B]{(B)}}(B)]")
  end
  
  def test_ignores_invalid_characters_with_default_action
    tokens = BracketTokenizer.tokenize("A{(B)[B]}")
    assert tokens.has_error?
    
    tokens = LazyBracketTokenizer.tokenize("A{(B)[B]}")
    assert !tokens.has_error?
  end
  
  def correct input_string
    result = BracketParser.parse(BracketTokenizer.tokenize(input_string))
    !result.has_error?
  end
end