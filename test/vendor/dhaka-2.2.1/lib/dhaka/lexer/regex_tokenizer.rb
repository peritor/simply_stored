module Dhaka
  module LexerSupport
    class RegexTokenizer < Tokenizer
    
      for_state TOKENIZER_IDLE_STATE do
        for_characters(Dhaka::LexerSupport::ALL_CHARACTERS) do
          create_token(curr_char, nil)
          advance
        end
      end
  
    end
  end
end