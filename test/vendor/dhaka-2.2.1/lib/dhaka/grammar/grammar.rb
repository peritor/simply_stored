module Dhaka
  
  # Reserved name for the start symbol for all grammars. 
  START_SYMBOL_NAME = "_Start_"
  END_SYMBOL_NAME   = "_End_" #:nodoc:
  
  # Productions for specific grammar symbols are defined in the context of this class.
  class ProductionBuilder
    # +symbol+ is the grammar symbol that productions are being defined for.
    def initialize(grammar, symbol)
      @grammar = grammar
      @symbol  = symbol
    end
  
    def to_byte(char)
      char.respond_to?(:bytes) ? char.bytes.first : char[0]
    end
  
    # Creates a new production for +symbol+ with an expansion of +expansion+. The options hash can include
    # a directive <tt>:prec</tt>, the value of which is a grammar symbol name. The precedence of the production is then
    # set to the precedence of the grammar symbol corresponding to that name. 
    #
    # See the arithmetic precedence grammar in the test suites for an example.
    def method_missing(production_name, expansion, options = {}, &blk)
      expansion_symbols = Array(expansion).collect {|name| @grammar.symbols[name]}
      production_args   = [@symbol, expansion_symbols, production_name.to_s, blk, @grammar.production_index]
      if precedence_symbol_name = options[:prec] 
        production_args << @grammar.symbol_for_name(precedence_symbol_name).precedence
      end
      
      production = Production.new(*production_args)
      @grammar.production_index += 1
      
      @symbol.nullable = true if expansion_symbols.empty?
      @grammar.productions_by_symbol[production.symbol] << production
      raise "Duplicate production named #{production.name}" if @grammar.productions_by_name[production.name]
      @grammar.productions_by_name[production.name] = production
    end
  end

  # The precedence builder defines three methods, +left+, +right+ and +nonassoc+. These accept arrays of grammar
  # symbols all of which have the same precedence level and associativity.
  #
  # See the arithmetic precedence grammar in the test suites for an example of how this works.
  class PrecedenceBuilder
    def initialize(grammar) #:nodoc:
      @grammar          = grammar
      @precedence_level = 0
    end
    
    [:left, :right, :nonassoc].each do |associativity| 
      define_method(associativity) do |symbols|
        assign_precedences associativity, symbols
      end
    end

    private
    def assign_precedences(associativity, symbol_names)
      symbol_names.each do |symbol_name|
        symbol            = @grammar.symbols[symbol_name]
        symbol.precedence = Precedence.new(@precedence_level, associativity)
      end
      @precedence_level += 1
    end
  end

  # Abstract base class for grammar specifications.
  # 
  # The following is a grammar specification for simple arithmetic. Precedences are specified as in Yacc -
  # in ascending order of binding strength, with equal-strength symbols on the same level. 
  # Production rules are specified for each symbol by specifying the name of the production (used when
  # encoding the Evaluator) and the expansion for that particular production. For example, the production named 
  # +addition+ expands the symbol <tt>'E'</tt> to the list of symbols <tt>['E', '+', 'E']</tt>.
  #
  #  class ArithmeticPrecedenceGrammar < Dhaka::Grammar
  #    precedences do
  #      left ['+', '-']
  #      left ['*', '/']
  #      nonassoc ['^']
  #    end
  #
  #    for_symbol(Dhaka::START_SYMBOL_NAME) do
  #      expression ['E']
  #    end
  #
  #    for_symbol('E') do
  #      addition ['E', '+', 'E']
  #      subtraction ['E', '-', 'E']
  #      multiplication ['E', '*', 'E']
  #      division ['E', '/', 'E']
  #      power ['E', '^', 'E']
  #      literal ['n']
  #      parenthetized_expression ['(', 'E', ')']
  #      negated_expression ['-', 'E'], :prec => '*'
  #    end
  #  end
  #
  # In the above grammar, the symbols <tt>+</tt> and <tt>-</tt> are declared as being +left+-associative, meaning that 
  # 1 + 2 + 3 is parsed as (1 + 2) + 3 as opposed to 1 + (2 + 3) (+right+-associativity). The symbol <tt>^</tt> is declared
  # +nonassoc+ which means that expressions such as 2 ^ 3 ^ 4 are not allowed (non-associative). <tt>+</tt> and <tt>-</tt> are listed 
  # before <tt>^</tt> which means that they bind lower, and an expression such as 2 + 3 ^ 5 will be always be parsed as
  # 2 + (3 ^ 5) and not (2 + 3) ^ 5.
  class Grammar
    class << self
      # Used for defining the Production-s for the symbol with name +symbol+. The block +blk+ is 
      # evaluated in the context of a ProductionBuilder.
      def for_symbol symbol, &blk
        symbol              = symbols[symbol]
        symbol.non_terminal = true
        ProductionBuilder.new(self, symbol).instance_eval(&blk)
      end

      # Used for defining the precedences and associativities of symbols. The block +blk+ is
      # evaluated in the context of a PrecedenceBuilder.
      def precedences &blk
        PrecedenceBuilder.new(self).instance_eval(&blk)
      end

      # Returns the grammar symbol identified by +name+
      def symbol_for_name(name)
        if symbols.has_key? name
          symbols[name]
        else
          raise "No symbol with name #{name} found"
        end
      end
      
      # Returns a list of all the Production-s in this grammar.
      def productions 
        productions_by_name.values
      end
      
      def productions_for_symbol(symbol) #:nodoc:
        productions_by_symbol[symbol]
      end
      
      def closure(kernel) #:nodoc:
        channels = Hash.new {|hash, start_item| hash[start_item] = Set.new}
        result = compute_closure(kernel) do |hash, item|    
          if item.next_symbol and item.next_symbol.non_terminal
            productions_by_symbol[item.next_symbol].each do |production|
              new_channel = spontaneous_channel(item, hash[Item.new(production, 0)])
              channels[item] << new_channel
            end
          end
        end
        [result, channels]
      end
      
      def passive_channel(start_item, end_item) #:nodoc:
        PassiveChannel.new(self, start_item, end_item)
      end
      
      def first(given_symbol) #:nodoc:
        cached_result = __first_cache[given_symbol] 
        return cached_result if cached_result
        result = compute_closure([given_symbol]) do |hash, symbol|
              productions_by_symbol[symbol].each do |production| 
                symbol_index = 0
                while next_symbol = production.expansion[symbol_index]
                  hash[next_symbol]
                  break unless next_symbol.nullable
                  symbol_index += 1
                end
              end if symbol.non_terminal
          end.values.select {|symbol| symbol.terminal}.to_set
        __first_cache[given_symbol] = result
        result
      end
      
      # Returns the Production identified by +name+.
      def production_named(name)
        productions_by_name[name]
      end
      
      # Returns the set of terminal symbols in the grammar.
      def terminal_symbols
        symbols.values.select {|symbol| symbol.terminal}
      end
      
      # Returns the set of non-terminal symbols in the grammar.
      def non_terminal_symbols
        symbols.values.select {|symbol| symbol.non_terminal}
      end
      
      # Export the grammar to a BNF-like format
      def to_bnf
        result = []
        last_symbol = nil
        productions.sort.each do |production|
          if production.symbol != last_symbol
            result << ""
            result << "#{production.symbol.name.inspect} :"
            last_symbol = production.symbol
          end
          result << "  | #{production.expansion.collect{|symbol| symbol.name.inspect}.join(' ')}"
        end
        result.join("\n")
      end
      
      private 
      
        def inherited(grammar)
          class << grammar
            attr_accessor :symbols, :productions_by_symbol, :productions_by_name, :start_symbol, :end_symbol, :__first_cache, :production_index
          end
          grammar.symbols               = Hash.new {|hash, name| hash[name] = GrammarSymbol.new(name)}
          grammar.productions_by_symbol = Hash.new {|hash, name| hash[name] = Set.new([])}
          grammar.productions_by_name   = {}
          grammar.end_symbol            = grammar.symbols[END_SYMBOL_NAME]
          grammar.start_symbol          = grammar.symbols[START_SYMBOL_NAME]
          grammar.__first_cache         = {}
          grammar.production_index      = 0
        end
  
        def spontaneous_channel(start_item, end_item)
          SpontaneousChannel.new(self, start_item, end_item)
        end

        def compute_closure(initial)
          closure_hash = ClosureHash.new do |hash, item|
            hash.dirty = true
            hash[item] = item
          end
          
          closure_hash.load_set(initial)
          
          loop do
            closure_hash.keys.each do |element|
              yield closure_hash, element
            end
            break unless closure_hash.dirty
            closure_hash.dirty = false
          end
          closure_hash
        end
      end
  end

end