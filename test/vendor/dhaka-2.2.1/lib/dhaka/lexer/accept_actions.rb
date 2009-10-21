module Dhaka
  module LexerSupport
    class AcceptAction
      attr_reader :pattern
      def initialize(pattern)
        @pattern = pattern
      end

      def call(lexer_run)
        lexer_run.accept(pattern)
      end

      def compile_to_ruby_source
        "accept(#{pattern.inspect})"
      end
      
      def to_dot
        "Accept #{pattern.inspect}"
      end
    end

    class LookaheadAcceptAction < AcceptAction
      def call(lexer_run)
          lexer_run.accept_last_saved_checkpoint(pattern)
      end

      def compile_to_ruby_source
        "accept_with_lookahead(#{pattern.inspect})"
      end
      
      def to_dot
        "Accept With Lookahead #{pattern.inspect}"
      end
    end
  end
end
