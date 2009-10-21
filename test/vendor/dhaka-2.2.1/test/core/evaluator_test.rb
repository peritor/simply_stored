require File.dirname(__FILE__) + '/../dhaka_test_helper'
require File.dirname(__FILE__) + '/simple_grammar'

class TestEvaluator < Test::Unit::TestCase
  def test_throws_exception_if_evaluation_rules_not_completely_defined_and_raise_error_option_set_to_true
    assert_raise(Dhaka::EvaluatorDefinitionError) do 
      eval(
      "class IncompleteSimpleEvaluator < Dhaka::Evaluator
        self.grammar = SimpleGrammar
        define_evaluation_rules(:raise_error => true) do
          for_start do
            something
          end
        
          for_literal do
            something
          end
        end
      end")
    end
  end
end