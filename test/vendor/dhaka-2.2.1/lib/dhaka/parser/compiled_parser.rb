module Dhaka
  # Abstract base class of all compiled Parsers. It is only used by generated code.
  class CompiledParser

    class << self
      private
        def inherited(compiled_parser)
          class << compiled_parser
            attr_accessor :states, :grammar, :start_state_id, :shift_actions, :reduce_actions
          end
          compiled_parser.states          = Hash.new do |hash, state_id| 
                                              hash[state_id] = ParserState.new(compiled_parser, {}, state_id)
                                            end
          compiled_parser.shift_actions   = Hash.new do |hash, state_id|
                                              hash[state_id] = ShiftAction.new(compiled_parser.states[state_id])
                                            end
          compiled_parser.reduce_actions  = Hash.new do |hash, production_name|
                                              hash[production_name] = ReduceAction.new(compiled_parser.grammar.production_named(production_name))
                                            end
        end

        def at_state x, &blk
          states[x].instance_eval(&blk)
        end
  
        def start_state
          states[start_state_id]
        end
  
        def start_with start_state_id
          self.start_state_id = start_state_id
        end
  
        def reduce_with production_name
          ReduceAction.new(grammar.production_named(production_name))
        end
  
        def shift_to state_id
          ShiftAction.new(states[state_id])
        end
        
        def inspect
          "<Dhaka::CompiledParser grammar : #{grammar}>"
        end
    end
  
    extend(ParserMethods)
  
  end

end