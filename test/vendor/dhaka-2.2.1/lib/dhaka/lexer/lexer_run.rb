module Dhaka
  # Represents a run of a lexer on a given input string.
  class LexerRun
    include Enumerable
    
    attr_reader :current_lexeme
    def initialize lexer, input
      @lexer, @input          = lexer, input
      @input_position         = 0
      @not_yet_accepted_chars = []
      @last_saved_checkpoints = {}
    end

    # Constructs a token of type +symbol_name+ from the +current_lexeme+.
    def create_token(symbol_name, value = current_lexeme.characters.join)
      Token.new(symbol_name, value, current_lexeme.input_position)
    end
  
    # Yields each token as it is recognized. Returns a TokenizerErrorResult if an error occurs during tokenization.
    def each
      reset_and_rewind
      loop do
        c = curr_char
        break if (c == "\0" && @not_yet_accepted_chars.empty? && !@current_lexeme.accepted?)
        dest_state  = @curr_state.transitions[c]
        unless dest_state
          return TokenizerErrorResult.new(@input_position) unless @current_lexeme.accepted?
          token = get_token
          yield token if token
          reset_and_rewind
        else
          @curr_state = dest_state
          @not_yet_accepted_chars << c
          @curr_state.process(self) 
          advance
        end
      end
      yield Token.new(END_SYMBOL_NAME, nil, nil)
    end
    
    def accept(pattern) #:nodoc:
      @current_lexeme.pattern = pattern
      @current_lexeme.concat @not_yet_accepted_chars
      @not_yet_accepted_chars = []
    end
    
    def save_checkpoint(pattern) #:nodoc:
      @last_saved_checkpoints[pattern] = (@current_lexeme.characters + @not_yet_accepted_chars)
    end
    
    def accept_last_saved_checkpoint(pattern) #:nodoc:
      @current_lexeme.pattern = pattern
      @current_lexeme.concat @not_yet_accepted_chars
      @not_yet_accepted_chars = @current_lexeme.characters[(@last_saved_checkpoints[pattern].size)..-1]
      @current_lexeme.characters = @last_saved_checkpoints[pattern].dup
    end
    
    private
      def reset_and_rewind
        @input_position -= @not_yet_accepted_chars.size
        @current_lexeme = Lexeme.new(@input_position)
        @curr_state     = @lexer.start_state
        @not_yet_accepted_chars = []
      end

      def curr_char
        (@input[@input_position] || 0).chr
      end
    
      def advance
        @input_position += 1
      end
    
      def get_token 
        instance_eval(&@lexer.action_for_pattern(@current_lexeme.pattern))
      end
  end
end   