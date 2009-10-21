module Dhaka
  # Abstract base class of all compiled Lexers. It is only used by generated code.
  class CompiledLexer

    class << self
      # Returns a LexerRun that tokenizes +input+.
      def lex input
        LexerRun.new(self, input)
      end

      def start_state #:nodoc:
        states[start_state_id]
      end

      def action_for_pattern pattern #:nodoc:
        specification.items[pattern].action
      end

      private
        def inherited(lexer)
          class << lexer
            attr_accessor :states, :specification, :start_state_id
          end
          lexer.states = Hash.new do |hash, state_id| 
                           hash[state_id] = LexerSupport::State.new(lexer, nil)
                         end
        end

        def at_state x, &blk
          states[x].instance_eval(&blk)
        end

        def start_with start_state_id
          self.start_state_id = start_state_id
        end
    
        def switch_to dest_state_id
          states[dest_state_id]
        end
    
        def inspect
          "<Dhaka::CompiledLexer specification : #{specification}>"
        end
    end
  end
end