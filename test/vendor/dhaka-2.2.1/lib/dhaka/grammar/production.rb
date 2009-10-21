module Dhaka
  class Production
    include Comparable
    
    attr_reader :symbol, :expansion, :name, :action, :priority

    def initialize(symbol, expansion, name, action, priority, precedence = nil)
      @symbol     = symbol
      @expansion  = expansion
      @name       = name
      @precedence = precedence
      @action     = action || proc { self }
      @priority   = priority
    end

    def precedence
      unless @precedence
        expansion.reverse_each do |symbol|
          if symbol.terminal
            @precedence = symbol.precedence
            break
          end
        end 
      end
      @precedence
    end

    def to_s #:nodoc:
      "#{name} #{symbol} ::= #{expansion.join(' ')}"
    end

    def <=> other
      priority <=> other.priority
    end
  end
end