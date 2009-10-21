require File.dirname(__FILE__) + '/arithmetic_grammar'

class ArithmeticTokenizer < Dhaka::Tokenizer
  
  digits        = ('0'..'9').to_a
  parenths      = %w| ( ) |
  operators     = %w| - + / * |
  functions     = %w| h l |
  arg_separator = %w| , |
  whitespace    = [' ']

  all_characters = digits + parenths + operators + functions + arg_separator + whitespace

  for_state Dhaka::TOKENIZER_IDLE_STATE do
    for_characters(all_characters - (digits + whitespace)) do
      create_token(curr_char, nil)
      advance
    end
    for_characters digits do
      create_token('n', '')
      switch_to :get_integer_literal
    end
    for_character whitespace do
      advance
    end
  end
  
  for_state :get_integer_literal do
    for_characters all_characters - digits do
      switch_to Dhaka::TOKENIZER_IDLE_STATE
    end
    for_characters digits do
      curr_token.value << curr_char
      advance
    end
  end
  
end

