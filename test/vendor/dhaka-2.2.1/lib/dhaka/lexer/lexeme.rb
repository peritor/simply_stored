module Dhaka
  # Represents a portion of the input string that has been recognized as matching a given lexer pattern.
  class Lexeme
    # The pattern matched by this lexeme.
    attr_accessor :pattern, :characters

    # +input_position+ is the index in the input stream that this lexeme starts at.
    attr_reader :input_position
    
    def initialize(input_position) #:nodoc:
      @input_position = input_position
      @characters = []
    end
    
    # The substring of the input stream that this lexeme is comprised of. 
    def value
      characters.join
    end

    def accepted? #:nodoc:
      pattern
    end
  
    def << char #:nodoc:
      characters << char
    end
  
    def concat chars #:nodoc:
      characters.concat chars
    end
  end
end 