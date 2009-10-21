module Dhaka
  # A subclass of Hash with a dirty flag
  class ClosureHash < Hash #:nodoc:
    attr_accessor :dirty

    def initialize
      super
      @dirty = false
    end

    def load_set(set)
      set.each {|item| self[item] = item}
    end
  end
end