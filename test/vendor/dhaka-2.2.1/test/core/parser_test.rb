require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/simple_grammar'
require File.dirname(__FILE__) + '/nullable_grammar'
require File.dirname(__FILE__) + '/lalr_but_not_slr_grammar'
require File.dirname(__FILE__) + '/another_lalr_but_not_slr_grammar'
require File.dirname(__FILE__) + '/rr_conflict_grammar'
require File.dirname(__FILE__) + '/sr_conflict_grammar'

class ParserTest < Test::Unit::TestCase
  def build_tokens(token_symbol_names)
    token_symbol_names.collect {|symbol_name| Dhaka::Token.new(symbol_name, nil, nil)}
  end
  
  def setup
    @grammar = SimpleGrammar
    @parser = Dhaka::Parser.new(@grammar)
  end

  def contains(given_member, set)
    set.inject(false) {|result, member| result ||= (Set.new(member) == Set.new(given_member))}
  end

  def assert_collection_equal(expected, actual)
    assert_equal(expected.size, actual.size)
    actual.each do |actual_member|
      assert(contains(actual_member, expected), "Should have found #{actual_member} in expected set.")
    end
  end
  
  def test_parser_generates_states_with_correct_items
    expected_states = [
                       ['_Start_ ::= -> S # [_End_]',
                          'S ::= -> E [#]',
                          'E ::= -> E - T [#-]',
                          'E ::= -> T [#-]',
                          'T ::= -> n [#-]',
                          'T ::= -> ( E ) [#-]'],
                       ['E ::= T -> [#)-]'],
                       ['T ::= n -> [#)-]'],
                       ['S ::= E -> [#]', 
                          'E ::= E -> - T [#-]'],
                       ['_Start_ ::= S -> # [_End_]'],
                       ['T ::= ( -> E ) [#)-]',
                          'E ::= -> E - T [)-]',
                          'E ::= -> T [)-]',
                          'T ::= -> n [)-]',
                          'T ::= -> ( E ) [)-]'],
                       ['E ::= E - -> T [#)-]',
                          'T ::= -> n [#)-]',
                          'T ::= -> ( E ) [#)-]'],
                       ['E ::= E - T -> [#)-]'],
                       ['T ::= ( E -> ) [#)-]',
                          'E ::= E -> - T [)-]'],
                       ['T ::= ( E ) -> [#)-]'],
                       ['_Start_ ::= S # -> [_End_]']]
    actual_states = @parser.send('states').collect {|state| state.items.values.collect {|item| item.to_s}}
    assert_collection_equal(expected_states, actual_states)
  end
  
  def test_parser_can_be_exported_to_dot_format
    dot_representation = @parser.to_dot
  end
  
  def test_parser_generates_parse_tree_given_a_stream_of_symbols
    parse_tree = @parser.parse(build_tokens(['(','n','-','(','n','-','n',')',')','-','n','#', Dhaka::END_SYMBOL_NAME]))
    assert_equal \
      ["literal",
       "term",
       "literal",
       "term",
       "literal",
       "subtraction",
       "parenthetized_expression",
       "subtraction",
       "parenthetized_expression",
       "term",
       "literal",
       "subtraction",
       "expression",
       "start"], parse_tree.linearize.collect {|node| node.production.name}
  end
  
  def get_linearized_parse_result(input, parser)
    parser.parse(build_tokens(input)).parse_tree.linearize.collect {|node| node.production.name}
  end
  
  def test_with_a_grammar_with_nullables_after_terminals
    grammar      = NullableGrammar
    parser       = Dhaka::Parser.new(grammar)
    parser_input = ['(','a',')', Dhaka::END_SYMBOL_NAME]
    assert_equal \
      ["literal_a",
       "empty_element_list",
       "concatenate_element_lists",
       "element_list",
       "tuple"], get_linearized_parse_result(parser_input, parser)
  end

  def test_with_a_grammar_that_is_not_SLR
    grammar      = LALRButNotSLRGrammar
    parser       = Dhaka::Parser.new(grammar)
    parser_input = ['b','d','c', Dhaka::END_SYMBOL_NAME]
    assert_equal(["A_d", "E_bAc", "start"], get_linearized_parse_result(parser_input, parser))
  end

  def test_with_another_grammar_that_is_not_SLR
    grammar      = AnotherLALRButNotSLRGrammar
    parser       = Dhaka::Parser.new(grammar)
    parser_input = ['*', 'id', '=', 'id', Dhaka::END_SYMBOL_NAME]
    assert_equal(["identifier", "l_value", "contents", "identifier", "l_value", "assignment"], get_linearized_parse_result(parser_input, parser))
  end

  def test_debug_output_with_a_grammar_that_should_generate_an_RR_conflict
    fake_logger = FakeLogger.new
    Dhaka::ParserState.any_instance.stubs(:unique_name).returns("StateXXX")
    parser = Dhaka::Parser.new(RRConflictGrammar, fake_logger)
    num_states = parser.send(:states).size
    assert_equal(['Created StateXXX.'] * num_states, fake_logger.debugs[0...num_states])
    assert_equal(1, fake_logger.errors.size)
    assert(fake_logger.errors.first.match(/^Parser Conflict at State:\n(.+)\n(.+)\nExisting: (.+)\nNew: (.+)\nLookahead: (.+)$/))
    assert_equal(["A ::= x y ->", "B ::= x y ->", "Reduce with xy A ::= x y", "Reduce with xy_again B ::= x y", "c"], 
        $~[1..5].sort)
  end

  def write_parser(parser)
    File.open('parser.dot', 'w') do |file|
      file << parser.to_dot
    end
  end
  
end
