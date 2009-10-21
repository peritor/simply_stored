require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/arithmetic_grammar'

class ArithmeticGrammarTest < Test::Unit::TestCase
  def test_first_with_nullable_non_terminals
    grammar = ArithmeticGrammar
    assert_equal(Set.new(['(', 'n', 'h', 'l']), Set.new(grammar.first(grammar.symbol_for_name('Args')).collect { |symbol| symbol.name }))
  end
end
