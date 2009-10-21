module Dhaka
  class Precedence #:nodoc:
    include Comparable
    attr_reader :precedence_level, :associativity
    
    def initialize(precedence_level, associativity)
      @precedence_level = precedence_level
      @associativity    = associativity
    end
    
    def <=> other
      precedence_level <=> other.precedence_level
    end
    
    def to_s
      "Precedence: #{precedence_level} Associativity: #{associativity}"
    end
  end
end