module Dhaka
  # Represents parser state items
  class Item #:nodoc:
    attr_reader :production, :next_item_index, :lookaheadset

    def initialize(production, next_item_index)
      @production      = production
      @next_item_index = next_item_index
      @lookaheadset    = Set.new
    end
    
    def next_symbol
      production.expansion[next_item_index]
    end
    
    def next_item
      Item.new(production, @next_item_index + 1)
    end
    
    def to_s(options = {})
      expansion_symbols = production.expansion.collect {|symbol| symbol.name}
      if next_item_index < expansion_symbols.size
        expansion_symbols.insert(next_item_index, '->')
      else
        expansion_symbols << '->'
      end
      expansion_repr = expansion_symbols.join(' ')

      item = "#{production.symbol} ::= #{expansion_repr}"
      item << " [#{lookaheadset.collect.sort}]" unless options[:hide_lookaheads]
      item
    end
   
    def eql?(other)
      production == other.production && next_item_index == other.next_item_index
    end

    def hash
      production.hash ^ next_item_index.hash
    end
  end
end