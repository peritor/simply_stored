require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + "/malformed_grammar"

class TestMalformedGrammar < Test::Unit::TestCase
  def test_must_have_a_start_symbol_in_order_to_generate_a_parser
    assert_raises(Dhaka::NoStartProductionsError) {Dhaka::Parser.new(MalformedGrammar)}
  end
end