module Dhaka
  # Each grammar symbol is uniquely identified by a string name. The name of a symbol can 
  # be anything (except the two reserved names <tt>'\_Start_'</tt> and <tt>'\_End_'</tt>) and need not 
  # correspond to its character representation. For example, an ampersand in the input string could 
  # be tokenized as a symbol with a name 'AND_OP'. You never have to directly instantiate a 
  # GrammarSymbol. It is done implicitly for you when you define a Grammar.
  class GrammarSymbol
    attr_reader :name
    attr_accessor :non_terminal, :nullable, :precedence, :associativity

    def initialize(name)
      @name = name
    end

    def terminal
      !non_terminal
    end

    def to_s #:nodoc:
      name.dup
    end

    def <=> other
      name <=> other.name
    end
  end
end