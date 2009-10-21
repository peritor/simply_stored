module Dhaka
  # The parser generator. To generate a parser from a grammar specification +ArithmeticPrecedenceGrammar+, one would
  # write:
  #   parser = Dhaka::Parser.new(ArithmeticPrecedenceGrammar)
  # 
  # To compile this parser to Ruby source as +ArithmeticPrecedenceParser+:
  #   parser.compile_to_ruby_source_as(:ArithmeticPrecedenceParser)
  # which returns a string of Ruby code.
  class Parser
    include ParserMethods
    attr_reader :grammar
  
    # Creates a new parser from the given grammar. Messages are logged by default to STDOUT
    # and the log level is WARN. Shift-reduce conflicts are reported at WARN and reduce-reduce conflicts
    # at ERROR. You may pass in your own logger. Logging at DEBUG shows a lot of progress output.
    def initialize(grammar, logger = nil)
      @shift_actions  = Hash.new {|hash, state| hash[state] = ShiftAction.new(state)}
      @reduce_actions = Hash.new {|hash, production| hash[production] = ReduceAction.new(production)}
      @logger         = logger || default_logger
      @transitions    = Hash.new {|hash, state| hash[state] = {}}
      @grammar        = grammar
      @channels       = Hash.new {|hash, start_item| hash[start_item] = []}
      @states = Hash.new do |hash, kernel|
          closure, channels = grammar.closure(kernel)
          channels.each do |start_item, channel_set|
            @channels[start_item].concat channel_set.to_a
          end
          new_state    = ParserState.new(self, closure)
          hash[kernel] = new_state
          @logger.debug("Created #{new_state.unique_name}.")
          new_state.transition_items.each do |symbol, items|
            destination_kernel = ItemSet.new(items.collect{|item| item.next_item})
            destination_state  = hash[destination_kernel]
            items.each {|item| @channels[item] << grammar.passive_channel(item, destination_state.items[item.next_item])}
            @transitions[new_state][symbol] = destination_state
          end
          new_state
      end
      initialize_states
    end

    # Returns the Ruby source of the generated parser compiled as +parser_class_name+. This can be written out to a file.
    def compile_to_ruby_source_as parser_class_name
      result = "class #{parser_class_name} < Dhaka::CompiledParser\n\n"
      result << "  self.grammar = #{grammar.name}\n\n"
      result << "  start_with #{start_state.id}\n\n"
      states.each do |state|
        result << "#{state.compile_to_ruby_source}\n\n"
      end
      result << "end"
      result
    end

    # Returns the dot representation of the parser. If <tt>:hide_lookaheads</tt> is set to true in the 
    # options hash, lookaheads are not written out to the parser states, which is helpful when there are dozens
    # of lookahead symbols for every item in every state.
    def to_dot(options = {})
      Dot::Digraph.new(:fontsize => 10, :shape => :box, :size => 5) do |g|
        states.each do |state|
          g.node(state, :label => state.items.values.collect{|item| item.to_s(options)}.join("\n"))
          @transitions[state].each do |symbol, dest_state|
            g.edge(state, dest_state, :label => symbol.name)
          end
        end
      end.to_dot
    end

    def inspect
      "<Dhaka::Parser grammar : #{grammar}>"
    end
  
    private
      attr_reader :start_state
      
    def states
      @states.values
    end
    
    def default_logger
      logger           = Logger.new(STDOUT)
      logger.level     = Logger::WARN
      logger.formatter = ParserLogOutputFormatter.new
      logger
    end

    def initialize_states
      start_productions = grammar.productions_for_symbol(grammar.start_symbol)
      raise NoStartProductionsError.new(grammar) if start_productions.empty?
      start_items = ItemSet.new(start_productions.collect {|production| Item.new(production, 0)})
      start_items.each {|start_item| start_item.lookaheadset << grammar.end_symbol}
      @start_state = @states[start_items]
      @logger.debug("Pumping #{@channels.keys.size} dirty items...")
      pump_channels @channels.keys
      @logger.debug("Generating shift actions...")
      generate_shift_actions
      @logger.debug("Generating reduce actions...")
      generate_reduce_actions
    end

    def generate_shift_actions
      @states.values.each do |state|
        @transitions[state].keys.each do |symbol|
          state.actions[symbol.name] = @shift_actions[@transitions[state][symbol]]
        end
      end
    end

    def generate_reduce_actions
      @states.values.each do |state|  
        state.items.values.select{ |item| !item.next_symbol }.each do |item| 
          create_reduction_actions_for_item_and_state item, state
        end
      end
    end

    def create_reduction_actions_for_item_and_state item, state
      item.lookaheadset.each do |lookahead| 
        new_action = @reduce_actions[item.production]
        if existing_action = state.actions[lookahead.name]
          if ReduceAction === existing_action
            message = ReduceReduceConflict.new(state, lookahead, new_action).resolve
            @logger.error(message)
          else
            message = ShiftReduceConflict.new(state, lookahead, new_action).resolve
            @logger.warn(message)
          end
        else
          state.actions[lookahead.name] = new_action
        end
      end
    end
  
    def pump_channels dirty_items
      loop do
        new_dirty_items = Set.new
        dirty_items.each do |dirty_item| 
          @channels[dirty_item].each do |channel| 
            new_dirty_items << channel.end_item if channel.pump
          end
        end
        break if new_dirty_items.empty?
        @logger.debug("#{new_dirty_items.size} dirty items...")
        dirty_items = new_dirty_items
      end
    end
  end

  # Raised when trying to create a Parser for a grammar that has no productions for the start symbol
  class NoStartProductionsError < StandardError
    def initialize(grammar) #:nodoc:
      @grammar = grammar
    end
    def to_s #:nodoc:
      "No start productions defined for #{@grammar.name}"
    end
  end

  class ParserLogOutputFormatter < Logger::Formatter #:nodoc:
    def call(severity, time, progname, msg)
      "\n%s -- %s: %s\n" % [ severity, progname, msg2str(msg)]
    end
  end

end

