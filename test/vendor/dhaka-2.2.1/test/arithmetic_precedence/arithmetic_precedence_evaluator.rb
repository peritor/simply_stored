require File.dirname(__FILE__) + '/arithmetic_precedence_grammar'

class ArithmeticPrecedenceEvaluator < Dhaka::Evaluator
  
  self.grammar = ArithmeticPrecedenceGrammar
  
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

    for_literal do
      child_nodes[0].token.value.to_i
    end

    for_parenthetized_expression do
      evaluate(child_nodes[1])
    end
    
    for_negated_expression do
      -evaluate(child_nodes[1])
    end
    
    for_power do
      evaluate(child_nodes[0])**evaluate(child_nodes[2])
    end

  end

end
