require File.dirname(__FILE__) + '/bracket_grammar'

class BracketTokenizer < Dhaka::Tokenizer
  
  all_characters = %w| ( [ { B } ] ) |

  for_state Dhaka::TOKENIZER_IDLE_STATE do
    for_characters(all_characters) do
      create_token(curr_char, nil)
      advance
    end
  end
  
end

class LazyBracketTokenizer < BracketTokenizer
  for_state Dhaka::TOKENIZER_IDLE_STATE do
    for_default do
      advance
    end
  end
end