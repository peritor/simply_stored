module Dhaka
  # Reserved constant used to identify the idle state of the tokenizer.
  TOKENIZER_IDLE_STATE = :idle_state 

  # Returned on successful tokenizing of the input stream. Supports iteration by including Enumerable, so it can
  # be passed in directly to the parser.
  class TokenizerSuccessResult
    include Enumerable
    
    def initialize(tokens)
      @tokens = tokens
    end
    
    # Returns false.
    def has_error?
      false
    end
    
    def each(&block)
      @tokens.each(&block)
    end
  end  

  # Returned when tokenizing fails due to an unexpected character in the input stream. 
  class TokenizerErrorResult
    # The index of the character that caused the error.
    attr_reader :unexpected_char_index
    
    def initialize(unexpected_char_index)
      @unexpected_char_index = unexpected_char_index
    end
    
    # Returns true.
    def has_error?
      true
    end
  end

  # A tokenizer state encapsulates actions that should be performed upon
  # encountering each permissible character for that state.
  class TokenizerState
    attr_reader :actions, :default_action

    def initialize
      @actions = {}
    end

    # Define the action (+blk+) to be performed when encountering any of +characters+ in the token stream.
    def for_characters(characters, &blk)
      characters.each do |character|
        actions[character] = blk
      end
    end

    alias for_character for_characters

    # define the action (+blk+) to be performed for any +characters+ that don't have an action to perform.
    def for_default(&blk)
      @default_action = blk
    end
  
    def to_s #:nodoc:
      actions.inspect
    end

  end

  # This abstract class contains a DSL for hand-coding tokenizers. Subclass it to implement tokenizers for specific grammars. 
  #
  # Tokenizers are state machines. Each state of a tokenizer is identified
  # by a Ruby symbol. The constant Dhaka::TOKENIZER_IDLE_STATE is reserved for the idle state of the tokenizer (the one
  # that it starts in).
  # 
  # The following is a tokenizer for arithmetic expressions with integer terms. The tokenizer starts in the idle state
  # creating single-character tokens for all characters excepts digits and whitespace. It shifts to
  # <tt>:get_integer_literal</tt> when it encounters a digit character and creates a token on the stack on which it
  # accumulates the value of the literal. When it again encounters a non-digit character, it shifts back to idle.
  # Whitespace is treated as a delimiter, but not shifted as a token.
  #
  #  class ArithmeticPrecedenceTokenizer < Dhaka::Tokenizer
  #
  #    digits = ('0'..'9').to_a
  #    parenths = ['(', ')']
  #    operators = ['-', '+', '/', '*', '^']
  #    functions = ['h', 'l']
  #    arg_separator = [',']
  #    whitespace = [' ']
  #
  #    all_characters = digits + parenths + operators + functions + arg_separator + whitespace
  #
  #    for_state Dhaka::TOKENIZER_IDLE_STATE do
  #      for_characters(all_characters - (digits + whitespace)) do
  #        create_token(curr_char, nil)
  #        advance
  #      end
  #      for_characters digits do
  #        create_token('n', '')
  #        switch_to :get_integer_literal
  #      end
  #      for_character whitespace do
  #        advance
  #      end
  #    end
  #
  #    for_state :get_integer_literal do
  #      for_characters all_characters - digits do
  #        switch_to Dhaka::TOKENIZER_IDLE_STATE
  #      end
  #      for_characters digits do
  #        curr_token.value << curr_char
  #        advance
  #      end
  #    end
  #
  #  end
  #
  # For languages where the lexical structure is very complicated, it may be too tedious to implement a Tokenizer by hand. 
  # In such cases, it's a lot easier to write a LexerSpecification using regular expressions and create a Lexer from that.
  class Tokenizer
    class << self
      # Define the action for the state named +state_name+.
      def for_state(state_name, &blk)
        states[state_name].instance_eval(&blk)
      end
    
      # Tokenizes a string +input+ and returns a TokenizerErrorResult on failure or a TokenizerSuccessResult on sucess.
      def tokenize(input)
        new(input).run
      end
      
      private
        def inherited(tokenizer)
          class << tokenizer
            attr_accessor :states, :grammar
          end
          tokenizer.states = Hash.new {|hash, key| hash[key] = TokenizerState.new}
        end
    end
    
    # The tokens shifted so far.
    attr_reader :tokens
    
    def initialize(input) #:nodoc:
      @input           = input
      @current_state   = self.class.states[TOKENIZER_IDLE_STATE]
      @curr_char_index = 0
      @tokens          = []
    end
  
    # The character currently being processed.
    def curr_char
      @input[@curr_char_index] and @input[@curr_char_index].chr 
    end
    
    # Advance to the next character.
    def advance
      @curr_char_index += 1
    end

    def inspect
      "<Dhaka::Tokenizer grammar : #{grammar}>"
    end
    
    # The token currently on top of the stack. 
    def curr_token
      tokens.last
    end
    
    # Push a new token on to the stack with symbol corresponding to +symbol_name+ and a value of +value+.
    def create_token(symbol_name, value)
      new_token = Dhaka::Token.new(symbol_name, value, @curr_char_index)
      tokens << new_token
    end
    
    # Change the active state of the tokenizer to the state identified by the symbol +state_name+.
    def switch_to state_name
      @current_state = self.class.states[state_name]
    end

    def run #:nodoc:
      while curr_char
        blk = @current_state.actions[curr_char] || @current_state.default_action
        return TokenizerErrorResult.new(@curr_char_index) unless blk
        instance_eval(&blk)
      end
      tokens << Dhaka::Token.new(Dhaka::END_SYMBOL_NAME, nil, nil)
      TokenizerSuccessResult.new(tokens)
    end
  end
end
