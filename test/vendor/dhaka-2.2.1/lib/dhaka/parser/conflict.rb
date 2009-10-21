module Dhaka
  # Represents parser shift-reduce and reduce-reduce conflicts and encapsulates logic for resolving them.
  class Conflict #:nodoc:
    def initialize(state, lookahead, new_action)
      @lookahead, @new_action, @state = lookahead, new_action, state
    end

    def build_conflict_message
      lines = ["Parser Conflict at State:", @state.to_s(:hide_lookaheads => true)]
      lines << "Existing: #{@state.actions[@lookahead.name]}"
      lines << "New: #{@new_action}"
      lines << "Lookahead: #{@lookahead}"
      lines.join("\n")
    end
  end


  class ReduceReduceConflict < Conflict #:nodoc:
    def resolve
      build_conflict_message
    end
  end

  class ShiftReduceConflict < Conflict #:nodoc:
    
    def resolve
      lines = [build_conflict_message]
      shift_precedence  = @lookahead.precedence
      reduce_precedence = @new_action.production.precedence
      if shift_precedence && reduce_precedence
        if shift_precedence > reduce_precedence
          lines << "Resolving with precedence. Choosing shift over reduce."
        elsif shift_precedence < reduce_precedence
          lines << "Resolving with precedence. Choosing reduce over shift."
          @state.actions[@lookahead.name] = @new_action
        else
          case shift_precedence.associativity
            when :left
              lines << "Resolving with left associativity. Choosing reduce over shift."
              @state.actions[@lookahead.name] = @new_action
            when :right
              lines << "Resolving with right associativity. Choosing shift over reduce."
            when :nonassoc
              lines << "Resolving with non-associativity. Eliminating action."
              @state.actions.delete(@lookahead.name)
          end
        end
      else
        lines << "No precedence rule. Choosing shift over reduce."
      end
      lines.join("\n")
    end
  end
end
