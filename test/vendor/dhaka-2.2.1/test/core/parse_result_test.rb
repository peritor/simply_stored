require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/simple_grammar'

class TestParseSuccessResult < Test::Unit::TestCase
  include Dhaka

  def composite_node(production, child_nodes, dot_name)
    node = ParseTreeCompositeNode.new(SimpleGrammar.production_named(production))
    node.child_nodes.concat child_nodes
    node.stubs(:object_id).returns(dot_name)
    node
  end

  def leaf_node(token, value, dot_name)
    node = ParseTreeLeafNode.new(Token.new(token, value, nil))
    node.stubs(:object_id).returns(dot_name)
    node
  end

  def test_parse_tree_can_be_exported_to_dot_format
    first_term    = composite_node('literal', [leaf_node('n', 1, "literal_1")], "first_term")
    second_term   = composite_node('literal', [leaf_node('n', 2, "literal_2")], "second_term")
    addition_term = leaf_node('-', nil, "subtraction_operator")
    tree          = composite_node('subtraction', [first_term, addition_term, second_term], "expression")
    result        = ParseSuccessResult.new(tree)
    assert_equal(
%(digraph x {
node [fontsize="10" shape="box" size="5"]
expression [label="subtraction E ::= E - T"]
expression -> first_term 
first_term [label="literal T ::= n"]
first_term -> literal_1 
literal_1 [label="n : 1"]
expression -> subtraction_operator 
subtraction_operator [label="-"]
expression -> second_term 
second_term [label="literal T ::= n"]
second_term -> literal_2 
literal_2 [label="n : 2"]
}), 
    result.to_dot)
  end

end