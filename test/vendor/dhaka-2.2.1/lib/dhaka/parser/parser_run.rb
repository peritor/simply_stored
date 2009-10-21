module Dhaka
  class ParserRun #:nodoc:

    def initialize(grammar, start_state, token_stream)
      @grammar      = grammar
      @node_stack   = []
      @state_stack  = [start_state]
      @token_stream = token_stream
      @symbol_queue = []
    end

    def run
      tokenize_result = token_stream.each do |token|
        @current_token = token
        @symbol_queue << @current_token.symbol_name
        error = execute_actions
        return error if error
        node_stack << ParseTreeLeafNode.new(@current_token)
        state_stack.last
      end
      return tokenize_result if TokenizerErrorResult === tokenize_result
      ParseSuccessResult.new(node_stack.first) if node_stack.first.head_node?
    end

    private

    attr_reader :state_stack, :token_stream, :node_stack

    def execute_actions
      while symbol_name = @symbol_queue.pop
        action = state_stack.last.actions[symbol_name]
        return ParseErrorResult.new(@current_token, state_stack.last) unless action
        instance_eval(&action.action_code)
      end
      nil
    end

  end
end