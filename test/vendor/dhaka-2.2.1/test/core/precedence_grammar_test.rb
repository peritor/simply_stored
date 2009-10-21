require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/precedence_grammar"

class TestPrecedenceGrammar < Test::Unit::TestCase
  def test_precedences_are_computed_correctly
    assert_equal(:left, PrecedenceGrammar.production_named('expression').precedence.associativity)
    assert_equal(:left, PrecedenceGrammar.production_named('whatever').precedence.associativity)
  end
end