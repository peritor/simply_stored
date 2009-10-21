module Dhaka
  # Returned on successful parsing of the input token stream. 
  class ParseSuccessResult < DelegateClass(ParseTreeCompositeNode)
    # Contains the parse result.
    attr_accessor :parse_tree 
    
    def initialize(parse_tree) #:nodoc:
      super
      @parse_tree = parse_tree
    end
    
    # This is false.
    def has_error? 
      false
    end
    
    # Returns the dot representation of the parse tree
    def to_dot
      Dot::Digraph.new(:fontsize => 10, :shape => :box, :size => 5) do |g|
        parse_tree.to_dot(g)
      end.to_dot
    end
    
    # Deprecated. Use the +parse_tree+ accessor.
    alias syntax_tree parse_tree
  end

  # Returned on unsuccessful parsing of the input token stream.
  class ParseErrorResult
    attr_reader :unexpected_token, :parser_state
    
    def initialize(unexpected_token, parser_state) #:nodoc:
      @unexpected_token = unexpected_token
      @parser_state = parser_state
    end
    
    # This is true.
    def has_error? 
      true
    end
    
    def inspect #:nodoc:
      "<Dhaka::ParseErrorResult unexpected_token=#{unexpected_token.inspect}>"
    end
  end
end
      
    
  
    