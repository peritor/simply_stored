module Dhaka
  # Represents channels for pumping of lookaheads between items
  class Channel #:nodoc:
    attr_reader :start_item, :end_item

    def initialize(grammar, start_item, end_item)
      @grammar    = grammar
      @start_item = start_item
      @end_item   = end_item
    end

    def propagate cargo
      initial_size = end_item.lookaheadset.size
      end_item.lookaheadset.merge(cargo)
      (end_item.lookaheadset.size - initial_size) > 0
    end

    def to_s
      "Channel from #{start_item} to #{end_item}"
    end

    def eql? other
      start_item.eql?(other.start_item) && end_item.eql?(other.end_item)
    end
    
    def hash
      start_item.hash ^ end_item.hash
    end
  end

  class SpontaneousChannel < Channel #:nodoc:
    def to_s
      "Spontaneous " + super
    end
    
    def pump
      follow_index = start_item.next_item_index + 1
      cargo        = Set.new
      while follow_symbol = start_item.production.expansion[follow_index]
        cargo.merge @grammar.first(follow_symbol)
        return propagate(cargo) unless follow_symbol.nullable
        follow_index += 1
      end
      cargo.merge start_item.lookaheadset
      propagate cargo
    end
  end

  class PassiveChannel < Channel #:nodoc:
    def to_s
      "Passive " + super
    end
    
    def pump
      propagate start_item.lookaheadset
    end
  end
end