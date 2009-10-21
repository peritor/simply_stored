module Dhaka
  module LexerSupport
    class StateMachine
      attr_reader :start_state
    
      def initialize start_key
        @states = Hash.new do |hash, key|
          new_state = new_state_for_key key
          hash[key] = new_state
          transition_characters(key).each do |char|
            dest_key                    = dest_key_for(key, char)
            dest_state                  = hash[dest_key]
            new_state.transitions[char] = dest_state
          end
          new_state
        end
        @start_state = @states[start_key]
      end

      def to_dot
        Dot::Digraph.new(:fontsize => 10, :shape => :circle, :size => 5) do |g|
          start = 'Start'
          g.node(start, :label => start)
          g.edge(start, @start_state)
          @states.values.each do |state|
            state_attributes = {}
            state_attributes.merge!(:shape => :doublecircle, :label => state.action.to_dot) if state.accepting?
            g.node(state, state_attributes)
            state.transitions.each do |transition_key, dest_state|
              g.edge(state, dest_state, :label => transition_key.inspect)
            end
          end
        end.to_dot
      end
    end
  end
end
