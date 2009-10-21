require File.dirname(__FILE__) + '/chittagong_grammar'

class ChittagongEvaluator < Dhaka::Evaluator

  self.grammar = ChittagongGrammar

  define_evaluation_rules do
    
    # No-ops
    ['no_terms', 'multiple_terms', 'single_term', 'some_terms'].each {|production_name| eval("for_#{production_name} do end")}

    for_program do
      evaluate(child_nodes[1])
    end

    for_multiple_main_body_statements do
      first = evaluate(child_nodes[0])
      return first if first.exception
      evaluate(child_nodes[2])
    end  

    for_multiple_function_body_statements do
      first = evaluate(child_nodes[0])
      return first if (first.exception || first.result)
      evaluate(child_nodes[2])
    end
    # lipi:function_defs
    for_function_definition do
      function_name    = evaluate(child_nodes[1])
      arg_declarations = evaluate(child_nodes[3])
      body             = child_nodes[6]
      @function_table[function_name] = Function.new(arg_declarations, body)
      ChittagongSuccessResult.new(nil)
    end
    # lipi:function_defs

    for_main_body_if_statement do
      checked_if_statement
    end
    
    for_function_body_if_statement do
      checked_if_statement
    end

    def checked_if_statement
      condition_eval = evaluate(child_nodes[1])
      return condition_eval if condition_eval.exception
      return evaluate(child_nodes[3]) if condition_eval.result
      ChittagongSuccessResult.new(nil)
    end
    
    for_main_body_if_else_statement do
      checked_if_else_statement
    end

    for_function_body_if_else_statement do
      checked_if_else_statement
    end
    
    def checked_if_else_statement
      condition_eval = evaluate(child_nodes[1])
      return condition_eval if condition_eval.exception
      if condition_eval.result
        evaluate(child_nodes[3])
      else
        evaluate(child_nodes[7])
      end
    end

    for_main_body_while_statement do
      checked_while_statement
    end
    
    for_function_body_while_statement do
      checked_while_statement
    end 
    
    def checked_while_statement
      loop do
        condition_eval = evaluate(child_nodes[1])
        return condition_eval if condition_eval.exception
        break unless condition_eval.result
        body_eval = evaluate(child_nodes[3])
        return body_eval if (body_eval.exception || body_eval.result)
      end
      ChittagongSuccessResult.new(nil)
    end

    for_assignment_statement do
      rhs = evaluate(child_nodes[2])
      return rhs if rhs.exception
      @stack[-1][evaluate(child_nodes[0])] = rhs.result
      ChittagongSuccessResult.new(nil)
    end
    
    for_print_statement do
      rhs = evaluate(child_nodes[1])
      return rhs if rhs.exception
      @output_stream << rhs.result.to_s
      ChittagongSuccessResult.new(nil)
    end

    for_function_call_statement do
      checked_function_call
    end
    
    for_function_call_expression do
      checked_function_call
    end
    # lipi:checked_function_call
    def checked_function_call
      function_name = evaluate(child_nodes[0])
      return ChittagongExceptionResult.new("Undefined function #{function_name}", 
          child_nodes[0]) unless @function_table.has_key?(function_name)
      
      arg_values = evaluate(child_nodes[2])
      return arg_values if arg_values.exception
      
      function = @function_table[function_name]
      return ChittagongExceptionResult.new(
        "Wrong number of arguments", child_nodes[1]
        ) unless function.args.size == arg_values.result.size
      new_frame = {}
      
      function.args.zip(arg_values.result).each do |arg_name, arg_value|
        new_frame[arg_name] = arg_value 
      end
      
      @stack << new_frame
      result = evaluate(function.body)
      @stack.pop
      
      result
    end
    # lipi:checked_function_call
    
    for_return_statement do 
      checked_unary_operation(child_nodes[1]){|x| x}
    end
    
    for_single_arg_declaration do
      [evaluate(child_nodes[0])]
    end
    
    for_no_arg_decl do
      []
    end
    
    for_multiple_arg_declarations do 
      evaluate(child_nodes[0]) + [evaluate(child_nodes[2])]
    end
    
    for_no_args do
      ChittagongSuccessResult.new([])
    end
    
    for_single_arg do
      checked_unary_operation(child_nodes[0]) {|x| [x]}
    end
    
    for_multiple_args do
      checked_binary_operation(child_nodes[0], child_nodes[2]) {|a, b| a + [b]}
    end
    
    for_variable_reference do
      variable_name = evaluate(child_nodes[0])
      return ChittagongExceptionResult.new("Undefined variable #{variable_name}", child_nodes[0]) unless @stack[-1].has_key? variable_name
      ChittagongSuccessResult.new(@stack[-1][variable_name])
    end

    for_subtraction do 
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a - b}
    end

    for_addition do
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a + b}
    end

    for_division do
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a.to_f / b}
    end

    for_multiplication do
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a * b}
    end
    
    for_power do
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a ** b}
    end
    
    for_less_than_comparison do
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a < b}
    end

    for_greater_than_comparison do
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a > b}
    end

    for_equality_comparison do
      checked_binary_operation(child_nodes[0], child_nodes[2]){|a, b| a == b}
    end
        
    def checked_binary_operation node1, node2
      node1_eval = evaluate(node1)
      node2_eval = evaluate(node2)
      return node1_eval if node1_eval.exception
      return node2_eval if node2_eval.exception
      ChittagongSuccessResult.new(yield(node1_eval.result, node2_eval.result))
    end

    for_negated_expression do
      checked_unary_operation(child_nodes[1]){|x| -x}
    end

    for_negation do
      checked_unary_operation(child_nodes[1]){|b| !b}
    end

    for_parenthetized_expression do
      checked_unary_operation(child_nodes[1]){|x| x}
    end
    
    def checked_unary_operation node
      node_eval = evaluate(node)
      return node_eval if node_eval.exception
      ChittagongSuccessResult.new(yield(node_eval.result))
    end
    
    for_function_name do
      token_value
    end
    
    for_variable_name do
      token_value
    end
    
    for_arg_declaration do
      token_value
    end
    
    for_literal do
      ChittagongSuccessResult.new(token_value.to_f)
    end

    def token_value
      child_nodes.first.token.value
    end
    # lipi:initialize
    def initialize(stack, output_stream)
      @stack          = stack
      @function_table = {}
      @output_stream  = output_stream
    end
    # lipi:initialize
  end

end

class ChittagongResult
  attr_reader :exception
end

class ChittagongSuccessResult < ChittagongResult
  attr_reader :result
  def initialize(result)
    @result = result
  end
end

class ChittagongExceptionResult < ChittagongResult
  attr_reader :node
  def initialize(exception, node)
    @exception = exception
    @node      = node
  end
end

class Function
  attr_reader :args, :body
  def initialize(args, body)
    @args = args
    @body = body
  end
end
