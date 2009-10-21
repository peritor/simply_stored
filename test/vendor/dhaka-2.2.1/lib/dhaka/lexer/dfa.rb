module Dhaka
  module LexerSupport
  
    # Raised when an invalid regular expression pattern is encountered 
    # in a LexerSpecification 
    class InvalidRegexException < StandardError 
    end

    class CheckpointAction
      attr_reader :pattern
      def initialize(pattern)
        @pattern = pattern
      end
      
      def call(lexer_run)
        lexer_run.save_checkpoint(pattern)
      end
      
      def compile_to_ruby_source
        "add_checkpoint(#{pattern.inspect})"
      end
    end
  
  
    class DFA < StateMachine #:nodoc:
      def initialize(regex)
        @regex = regex
      
        tokenize_result = RegexTokenizer.tokenize(@regex)
        raise InvalidRegexException.new(tokenize_error_message(tokenize_result)) if tokenize_result.has_error?
        
        parse_result = RegexParser.parse(tokenize_result)
        raise InvalidRegexException.new(parse_error_message(parse_result)) if parse_result.has_error?
      
        ast = parse_result
        ast.calculate_follow_sets

        super(ItemSet.new(ast.first))
      end
    
      def tokenize_error_message(tokenize_result)
        "Invalid character #{@regex[tokenize_result.unexpected_char_index].chr}: #{@regex.dup.insert(tokenize_result.unexpected_char_index, '>>>')}"
      end

      def parse_error_message(parse_result)
        unexpected_token = parse_result.unexpected_token
        if unexpected_token.symbol_name == END_SYMBOL_NAME
          "Unexpected end of regex."
        else
          "Unexpected token #{parse_result.unexpected_token.symbol_name}: #{@regex.dup.insert(parse_result.unexpected_token.input_position, '>>>')}"
        end
      end
    
      def dest_key_for key, char
        result = ItemSet.new
        key.each do |position|
          result.merge(position.follow_set) if position.character == char
        end
        result
      end
    
      def new_state_for_key key
        accepting = key.detect {|position| position.accepting} 
        if accepting
          new_state = State.new(self, accepting.action(@regex))
        else
          new_state = State.new(self)
        end
        if key.any? {|position| position.checkpoint}
          new_state.checkpoint_actions << CheckpointAction.new(@regex)
        end
        new_state
      end
    
      def transition_characters key
        result = Set.new
        key.each do |node|
          result << node.character unless (node.accepting || node.checkpoint)
        end
        result
      end
    
      def match(input)
        DFARun.new(self, input).match
      end
    end
    
    class DFARun
      def initialize(dfa, input)
        @dfa, @input = dfa, input
        @matched = ""
        @not_yet_accepted = ""
        @curr_state = @dfa.start_state
      end
      
      def match
        @input.unpack("C*").each do |i|
          break unless dest_state = @curr_state.transitions[i.chr]
          @not_yet_accepted << i.chr
          @curr_state = dest_state
          @curr_state.process(self)
        end
        @matched
      end

      def save_checkpoint(pattern)
        @last_saved_checkpoint = @matched + @not_yet_accepted
      end
      
      def accept(pattern)
        @matched.concat @not_yet_accepted
        @not_yet_accepted = ""
      end

      def accept_last_saved_checkpoint(pattern)
        @matched = @last_saved_checkpoint
        @not_yet_accepted = ""
      end
    end
  end
end
