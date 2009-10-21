require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/arithmetic_precedence_grammar'

class TestArithmeticPrecedenceGrammar < Test::Unit::TestCase
  def setup
    @addop = ArithmeticPrecedenceGrammar.symbol_for_name('+')
    @subop = ArithmeticPrecedenceGrammar.symbol_for_name('-')
    @mulop = ArithmeticPrecedenceGrammar.symbol_for_name('*')
    @divop = ArithmeticPrecedenceGrammar.symbol_for_name('/')
    @powop = ArithmeticPrecedenceGrammar.symbol_for_name('^')
  end
  
  def test_precedence_levels_and_associativity_of_terminals
    assert_equal(0, @addop.precedence.precedence_level)
    assert_equal(0, @subop.precedence.precedence_level)
    assert_equal(1, @mulop.precedence.precedence_level)
    assert_equal(1, @divop.precedence.precedence_level)
    assert_equal(2, @powop.precedence.precedence_level)
    assert_equal(:left, @addop.precedence.associativity)
    assert_equal(:left, @subop.precedence.associativity)
    assert_equal(:left, @mulop.precedence.associativity)
    assert_equal(:left, @divop.precedence.associativity)
    assert_equal(:nonassoc, @powop.precedence.associativity)
  end
  def test_precedence_of_production
    assert_equal(@addop.precedence, ArithmeticPrecedenceGrammar.production_named("addition").precedence)
    assert_equal(@mulop.precedence, ArithmeticPrecedenceGrammar.production_named("multiplication").precedence)
    assert_equal(@mulop.precedence, ArithmeticPrecedenceGrammar.production_named("negated_expression").precedence)
  end
end