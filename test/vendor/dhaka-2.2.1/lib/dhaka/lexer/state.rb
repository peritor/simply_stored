module Dhaka
  module LexerSupport
    
    class State
      attr_reader :transitions, :checkpoint_actions, :action
      def initialize(state_machine, action=nil)
        @state_machine      = state_machine
        @transitions        = {}
        @checkpoint_actions = []
        @action             = action
      end
      
      def accepting?
        @action
      end
      
      def process lexer_run
        checkpoint_actions.each {|action| action.call(lexer_run)}
        action.call(lexer_run) if accepting?
      end
      
      def for_characters *characters, &blk
        dest_state = @state_machine.instance_eval(&blk)
        characters.each do |char|
          transitions[char] = dest_state
        end
      end
      
      def add_checkpoint(pattern)
        checkpoint_actions << LexerSupport::CheckpointAction.new(pattern)
      end
      
      def accept(pattern)
        @action = AcceptAction.new(pattern)
      end
      
      def accept_with_lookahead(pattern)
        @action = LookaheadAcceptAction.new(pattern)
      end
      
      def recognize pattern
        @pattern = pattern
      end
      
      def compile_to_ruby_source
        result  = "  at_state(#{object_id}) {\n"
        result << "    #{action.compile_to_ruby_source}\n" if action
        checkpoint_actions.each do |checkpoint_action|
          result << "    #{checkpoint_action.compile_to_ruby_source}\n"
        end
        transition_keys_by_destination_state = Hash.new {|hash, key| hash[key] = []}
        transitions.each do |key, dest_state|
          transition_keys_by_destination_state[dest_state.object_id] << key
        end

        transition_keys_by_destination_state.keys.each do |state_id|
          transition_keys = transition_keys_by_destination_state[state_id].collect {|transition_key| "#{transition_key.inspect}"}.join(', ')
          result << "    for_characters(#{transition_keys}) { switch_to #{state_id} }\n"
        end

        result << "  }"
        result
      end
    end
    
  end
end
  
