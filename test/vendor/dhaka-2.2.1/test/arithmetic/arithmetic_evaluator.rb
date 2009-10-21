require File.dirname(__FILE__) + '/arithmetic_grammar'

class ArithmeticEvaluator < Dhaka::Evaluator
  
  self.grammar = ArithmeticGrammar
  
  define_evaluation_rules do
    
    for_subtraction do 
      evaluate(child_nodes[0]) - evaluate(child_nodes[2])
    end

    for_addition do
      evaluate(child_nodes[0]) + evaluate(child_nodes[2])
    end

    for_division do
      evaluate(child_nodes[0]).to_f/evaluate(child_nodes[2]) 
    end

    for_multiplication do
      evaluate(child_nodes[0]) * evaluate(child_nodes[2])
    end

    for_getting_literals do
      child_nodes[0].token.value
    end

    for_unpacking_parenthetized_expression do
      evaluate(child_nodes[1])
    end
    
    for_empty_args do
      []
    end

    for_evaluating_function do
      evaluate(child_nodes[0]).call evaluate(child_nodes[2])
    end
  
    for_concatenating_args do
      [evaluate(child_nodes[0])]+evaluate(child_nodes[2])
    end
  
    for_single_args do
      [evaluate(child_nodes[0])]
    end
  
    for_min_function do
      @min_function
    end
  
    for_max_function do
      @max_function
    end

  end
  
  def initialize(min_function, max_function)
    @min_function = min_function
    @max_function = max_function
  end

end
