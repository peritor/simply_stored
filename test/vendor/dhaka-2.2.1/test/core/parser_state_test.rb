require File.dirname(__FILE__) + '/../dhaka_test_helper'

class TestParserState < Test::Unit::TestCase
  include Dhaka
  def test_unique_identifier
    states = (0...5).collect {|i| ParserState.new(nil, {})}
    ids = Set.new
    states.each do |state|
      assert(/^State(\d+)$/ =~ state.unique_name)
      ids << $1.to_i
    end
    assert_equal(5, ids.size)
  end
  
  def test_to_s_method
    options = {:some_option => true}
    item1 = mock()
    item1.stubs(:to_s).with(options).returns("i'm item 1")
    item2 = mock()
    item2.stubs(:to_s).with(options).returns("i'm item 2")
    state = ParserState.new(nil, {item1 => item1, item2 => item2})
    assert_equal(["i'm item 1", "i'm item 2"], state.to_s(options).split("\n").sort)
  end
end