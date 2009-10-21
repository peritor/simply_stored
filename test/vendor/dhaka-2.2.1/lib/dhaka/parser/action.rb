module Dhaka
  # Encapsulates code for Parser actions.
  class Action #:nodoc:
    attr_reader :action_code
  end

  class ShiftAction < Action #:nodoc:
    attr_reader :destination_state
    def initialize destination_state
      @destination_state = destination_state
      @action_code       = Proc.new do
        state_stack << destination_state
        []
      end
    end
    
    def compile_to_ruby_source
      "shift_to #{destination_state.id}"
    end
    
    def to_s
      "Shift"
    end
  end

  class ReduceAction < Action #:nodoc:
    attr_reader :production
    
    def initialize(production)
      @production  = production
      @action_code = Proc.new do
        composite_node = ParseTreeCompositeNode.new(production)

        production.expansion.each do |symbol|
          state_stack.pop
          composite_node.child_nodes.unshift(node_stack.pop)
        end

        node_stack << composite_node.instance_eval(&production.action)

        unless composite_node.head_node?
          @symbol_queue.concat [@current_token.symbol_name, production.symbol.name]
        end
      end
    end
    
    def compile_to_ruby_source
      "reduce_with #{production.name.inspect}"
    end
    
    def to_s
      "Reduce with #{production}"
    end
  end
end
