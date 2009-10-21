module Dhaka
  class ParserState #:nodoc:
    attr_accessor :items, :actions, :id
  
    @@state_id = 0
  
    def self.next_state_id
      result      = @@state_id
      @@state_id += 1
      result
    end
  
    def initialize(parser, items, id=nil)
      @parser  = parser
      @items   = items
      @actions = {}
      @id      = id || ParserState.next_state_id
    end

    def transition_items
      result = Hash.new {|h, k| h[k] = ItemSet.new()}
      items.values.each do |item|
        result[item.next_symbol] << item if item.next_symbol
      end
      result
    end

    def unique_name
      "State#{id}"
    end

    def compile_to_ruby_source
      result = "  at_state(#{id}) {\n"

      symbol_names_by_action = Hash.new {|hash, key| hash[key] = []}
      actions.each do |symbol_name, action|
        symbol_names_by_action[action] << symbol_name
      end
      
      symbol_names_by_action.keys.each do |action|
        symbol_names = symbol_names_by_action[action].collect {|symbol_name| "#{symbol_name.inspect}"}.join(', ')
        result << "    for_symbols(#{symbol_names}) { #{action.compile_to_ruby_source} }\n"
      end
      
      result << "  }"
      result
    end
    
    def for_symbols *symbol_names, &blk
      symbol_names.each do |symbol_name|
        actions[symbol_name] = @parser.instance_eval(&blk)
      end
    end
  
    alias :for_symbol :for_symbols
  
    def to_s(options = {})
      items.values.collect{|item| item.to_s(options)}.join("\n")
    end
  
  end

  class ItemSet < Set #:nodoc:
    def hash
      result = 5381
      each { |item| result ^= item.hash }
      result
    end
    
    def eql? other
      self == other
    end
  end
end
