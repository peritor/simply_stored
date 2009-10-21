module Dhaka
  # The lexer generator. To generate a lexer from a lexer specification +MyLexerSpecification+:
  #   lexer = Dhaka::Lexer.new(MyLexerSpecification)
  # 
  # To compile this lexer as +MyLexer+ to a string of Ruby source:
  #   lexer.compile_to_ruby_source_as(:MyLexer)
  class Lexer < LexerSupport::StateMachine
    attr_reader :specification

    # Creates a new lexer from a given specification. 
    def initialize(specification)
      dfas           = {}
      @specification = specification
      specification.items.each do |pattern, item|
        dfas[pattern] = LexerSupport::DFA.new(pattern)
      end
      super(ItemSet.new(dfas.values.collect{|dfa| dfa.start_state}))
    end
  
    # Compiles the lexer to Ruby code that when executed, reloads all the states and actions of the lexer 
    # into a class named +lexer_class_name+.
    def compile_to_ruby_source_as lexer_class_name
      result  =   "class #{lexer_class_name} < Dhaka::CompiledLexer\n\n"
      result <<   "  self.specification = #{specification.name}\n\n"
      result <<   "  start_with #{start_state.object_id}\n\n"
      @states.each do |key, state|
        result << "#{state.compile_to_ruby_source}\n\n"
      end
      result <<   "end"
      result
    end
  
    # Returns a LexerRun that tokenizes +input+.
    def lex input
      LexerRun.new(self, input)
    end
    
    def action_for_pattern pattern #:nodoc
      @specification.items[pattern].action
    end
    
    private
      def new_state_for_key key
        accepting_states = key.select {|state| state.accepting?}
        unless accepting_states.empty?
          highest_precedence_state = accepting_states.min {|a, b| @specification.items[a.action.pattern] <=> @specification.items[b.action.pattern]}
          new_state = LexerSupport::State.new(self, highest_precedence_state.action)
        else
          new_state = LexerSupport::State.new(self)
        end
        key.select {|state| !state.checkpoint_actions.empty?}.each do |state|
          new_state.checkpoint_actions.concat state.checkpoint_actions
        end
        new_state
      end
  
      def transition_characters states
        states.collect{|state| state.transitions.keys}.flatten.uniq
      end

      def dest_key_for states, char
        result = ItemSet.new
        states.each do |state|
          dest_state = state.transitions[char]
          result << dest_state if dest_state
        end  
        result
      end
  end
end
