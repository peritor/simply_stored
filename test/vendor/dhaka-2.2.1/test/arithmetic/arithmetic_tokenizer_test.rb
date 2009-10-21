require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/arithmetic_tokenizer"

class TestArithmeticTokenizer < Test::Unit::TestCase
  def test_returns_end_of_input_token_for_empty_input
    assert_equal([token(Dhaka::END_SYMBOL_NAME, nil)], ArithmeticTokenizer.tokenize([]).to_a)
  end
  
  def test_tokenizes_given_a_string_input
    assert_equal([token('n', 2), token('-', nil), token('n', 4), token(Dhaka::END_SYMBOL_NAME, nil)], ArithmeticTokenizer.tokenize('2 - 4').to_a) 
  end
  
  def test_a_longer_input
    actual = ArithmeticTokenizer.tokenize('2+(3 / (7 - 5))').to_a
    assert_equal([token('n', 2), token('+', nil), token('(', nil), token('n', 3), token('/', nil), token('(', nil), token('n', 7), token('-', nil), token('n', 5), token(')', nil) , token(')', nil), token(Dhaka::END_SYMBOL_NAME, nil)], actual)
  end

  def test_another_input_with_multi_digit_numbers
    actual = ArithmeticTokenizer.tokenize('2034 +(3433 / (7 - 5))').to_a
    assert_equal([token('n', 2034), token('+', nil), token('(', nil), token('n', 3433), token('/', nil), token('(', nil), token('n', 7), token('-', nil), token('n', 5), token(')', nil) , token(')', nil), token(Dhaka::END_SYMBOL_NAME, nil)], actual)
  end

  def test_an_input_with_unrecognized_characters
    result = ArithmeticTokenizer.tokenize('2+(3 / (7 -& 5))')
    assert(result.has_error?)
    assert_equal(11, result.unexpected_char_index)
  end

  def test_another_input_with_illegal_characters
    result = ArithmeticTokenizer.tokenize('2034 +(34b3 / (7 - 5))')
    assert(result.has_error?)
    assert_equal(9, result.unexpected_char_index)
  end

  def token(symbol_name, value)
    Dhaka::Token.new(symbol_name, value ? value.to_s : nil, nil)
  end
end