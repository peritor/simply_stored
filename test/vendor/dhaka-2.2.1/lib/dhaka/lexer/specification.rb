module Dhaka
  # Abstract base class for lexer specifications.
  # 
  # Use this to specify the transformations that will be performed when the lexer recognizes a given pattern. Actions are listed in
  # descending order of priority. For example in the following lexer specification:
  # 
  #   class LexerSpec < Dhaka::LexerSpecification
  #     for_pattern 'zz' do
  #       "recognized two zs"
  #     end
  #   
  #     for_pattern '\w(\w|\d)*' do
  #       "recognized word token #{current_lexeme.value}"
  #     end
  #   
  #     for_pattern '(\d)+(\.\d+)?' do
  #       "recognized number #{current_lexeme.value}"
  #     end
  #   
  #     for_pattern ' +' do
  #       #ignores whitespace
  #     end
  #     
  #     for_pattern "\n+" do
  #       "recognized newline"
  #     end
  #   end
  #  
  # the pattern 'zz' takes precedence over the pattern immediately below it, so the lexer will announce that it has recognized two
  # 'z's instead of a word token.
  #  
  # The patterns are <i>not</i> Ruby regular expressions - a lot of operators featured in Ruby's regular expression engine are not yet supported.
  # See http://dhaka.rubyforge.org/regex_grammar.html for the current syntax. Patterns may be specified using Ruby regular expression literals 
  # as well as string literals. 
  # 
  # There are a few things to keep in mind with regard to the regular expression implementation:
  # * The greediest matching expression always wins. Precedences are only used when the same set of characters matches
  #   multiple expressions.
  # * All quantifiers are greedy. There is as yet no support for non-greedy modifiers.
  # * The lookahead operator "/" can behave in counter-intuitive ways in situations where the pre-lookahead-operator expression and the 
  #   post-lookahead-operator expression have characters in common. For example the expression "(ab)+/abcd", when applied to the input
  #   "abababcd" will yield "ababab" as the match instead of "abab". A good thumb rule is that the pre-lookahead expression is greedy.
  # * There is no support for characters beyond those specified in the grammar above. This means that there is no support for extended ASCII or unicode characters.

  
  class LexerSpecification
    class << self
      # Associates +blk+ as the action to be performed when a lexer recognizes +pattern+. When Lexer#lex is invoked, 
      # it creates a LexerRun object that provides the context for +blk+ to be evaluated in. Methods available in this block
      # are LexerRun#current_lexeme and LexerRun#create_token.
      def for_pattern(pattern, &blk)
        source = case pattern
                   when String then pattern
                   when Regexp then pattern.source
                 end
        items[source] = LexerSpecificationItem.new(source, priority, blk)
        self.priority += 1
      end
      
      # Use this to automatically handle escaping for regular expression metacharacters. For example, 
      #   for_symbol('+') { ... }
      # translates to:
      #   for_pattern('\+') { ... }
      def for_symbol(symbol, &blk)
        if LexerSupport::OPERATOR_CHARACTERS.include?(symbol)
          for_pattern("\\#{symbol}", &blk)
        else
          for_pattern(symbol, &blk)
        end
      end
      
      private
        def inherited(specification)
          class << specification
            attr_accessor :items, :priority
          end
          specification.items = {}
          specification.priority = 0
        end
    
    end
  end
  
  class LexerSpecificationItem #:nodoc:
    include Comparable
    attr_reader :pattern, :action, :priority
    def initialize(pattern, priority, action)
      @pattern, @priority, @action = pattern, priority, action
    end
  
    def <=> other
      priority <=> other.priority
    end
  end
end
    
