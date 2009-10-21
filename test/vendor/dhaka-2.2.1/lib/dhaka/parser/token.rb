module Dhaka
  # Represents a portion of the input character stream that is mapped by the tokenizer
  # to a symbol in the grammar. The attribute +input_position+ contains the start index position of the original
  # string input that this token came from. It can be used to report errors by indicating the specific portion
  # of the input where the error occurred.
  class Token
    attr_accessor :symbol_name, :value, :input_position
    def initialize(symbol_name, value, input_position)
      @symbol_name    = symbol_name
      @value          = value
      @input_position = input_position
    end
    
    def to_s #:nodoc:
      value ? "#{symbol_name} : #{value}" : "#{symbol_name}"
    end
    
    def == other
      symbol_name == other.symbol_name && value == other.value
    end
  end
end