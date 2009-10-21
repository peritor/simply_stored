require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/simple_grammar'

class SimpleGrammarTest < Test::Unit::TestCase
  def setup
    @grammar = SimpleGrammar
  end
  
  def test_loads_symbols_and_classifies_them
    expected_non_terminals = Set.new(['E', 'S', 'T', Dhaka::START_SYMBOL_NAME])
    expected_terminals     = Set.new(['-', 'n', '(', ')', '#', Dhaka::END_SYMBOL_NAME])
    assert_equal(expected_non_terminals, Set.new(@grammar.non_terminal_symbols.collect {|symbol| symbol.name}))
    assert_equal(expected_terminals, Set.new(@grammar.terminal_symbols.collect {|symbol| symbol.name}))
  end
  
  def test_creates_productions
    productions_for_E = @grammar.productions_for_symbol(@grammar.symbol_for_name('E'))
    assert(productions_for_E.size == 2)
    expected_productions_for_E = Set.new(['subtraction E ::= E - T', 'term E ::= T'])
    assert_equal(expected_productions_for_E, Set.new(productions_for_E.collect {|production| production.to_s}))
    productions_for_start = @grammar.productions_for_symbol(@grammar.start_symbol)
    assert(productions_for_start.size == 1)
    expected_productions_for_start = Set.new(['start _Start_ ::= S #'])
    assert_equal(expected_productions_for_start, Set.new(productions_for_start.collect {|production| production.to_s}))
  end
  
  def test_symbols_in_productions_use_the_flyweight_pattern
    assert_same(@grammar.production_named('subtraction').symbol, @grammar.production_named('term').symbol)
    assert_same(@grammar.production_named('expression').expansion.first, @grammar.production_named('subtraction').expansion.first)
  end
  
  def test_first_with_non_terminal
    expected_symbols = Set.new(['(', 'n'])
    assert_equal(expected_symbols, Set.new(@grammar.first(@grammar.symbol_for_name('E')).collect {|symbol| symbol.name}))
  end

  def test_first_with_terminal
    expected_symbols = Set.new(['('])
    assert_equal(expected_symbols, Set.new(@grammar.first(@grammar.symbol_for_name('(')).collect {|symbol| symbol.name}))
  end

  def test_computes_closures_and_channels_given_a_kernel
    start_production  = @grammar.production_named('start')
    start_item        = Dhaka::Item.new(start_production, 0)
    kernel            = Set.new([start_item])
    closure, channels = @grammar.closure(kernel)
    expected_items    = Set.new(['_Start_ ::= -> S # []',
                              'S ::= -> E []',
                              'E ::= -> E - T []',
                              'E ::= -> T []',
                              'T ::= -> n []',
                              'T ::= -> ( E ) []'])
    expected_channels = Set.new([
          'Spontaneous Channel from E ::= -> E - T [] to E ::= -> E - T []',
          'Spontaneous Channel from S ::= -> E [] to E ::= -> T []',
          'Spontaneous Channel from E ::= -> T [] to T ::= -> n []',
          'Spontaneous Channel from S ::= -> E [] to E ::= -> E - T []',
          'Spontaneous Channel from E ::= -> T [] to T ::= -> ( E ) []',
          'Spontaneous Channel from E ::= -> E - T [] to E ::= -> T []',
          'Spontaneous Channel from _Start_ ::= -> S # [] to S ::= -> E []'
          ])
    assert_equal(expected_items, Set.new(closure.values.collect{|item| item.to_s}))
    assert_equal(expected_channels, Set.new(channels.values.collect{|set| set.to_a}.flatten.collect{|item| item.to_s}))
  end
  
  def test_export_grammar_to_bnf
    assert_equal(
'
"_Start_" :
  | "S" "#"

"S" :
  | "E"

"E" :
  | "E" "-" "T"
  | "T"

"T" :
  | "n"
  | "(" "E" ")"', @grammar.to_bnf)
  end
end