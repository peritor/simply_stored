module Dhaka
  # These are composite nodes of the syntax tree returned by the successful parsing of a token stream.
  class ParseTreeCompositeNode 
    attr_reader :production, :child_nodes
    
    def initialize(production) #:nodoc:
      @production  = production
      @child_nodes = []
    end  
    def linearize #:nodoc:
      child_nodes.collect {|child_node| child_node.linearize}.flatten + [self]
    end
    
    def tokens
      child_nodes.collect{|child_node| child_node.tokens}.flatten
    end
    
    def to_s #:nodoc:
      "CompositeNode: #{production.symbol} --> [#{child_nodes.join(", ")}]"
    end
    
    # Returns the dot representation of this node.
    def to_dot graph
      graph.node(self, :label => production)
      child_nodes.each do |child|
        graph.edge(self, child)
        child.to_dot(graph)
      end
    end
    
    def head_node? #:nodoc:
      production.symbol.name == START_SYMBOL_NAME
    end

  end

  # These are leaf nodes of syntax trees. They contain tokens.
  class ParseTreeLeafNode 
    attr_reader :token
    
    def initialize(token) #:nodoc:
      @token = token
    end
    
    def linearize #:nodoc:
      []
    end
    
    def tokens
      [token]
    end
    
    def to_s #:nodoc:
      "LeafNode: #{token}"
    end
    
    # Returns the dot representation of this node.
    def to_dot(graph)
      graph.node(self, :label => token)
    end
    
    def head_node? #:nodoc:
      false
    end
  end
end