class ArithmeticGrammar < Dhaka::Grammar

  for_symbol(Dhaka::START_SYMBOL_NAME) do
    expression                         %w| E |
  end

  for_symbol('E') do
    subtraction                        %w| E - T |
    addition                           %w| E + T |
    term                               %w| T |
  end

  for_symbol('T') do
    factor                             %w| F |
    division                           %w| T / F |
    multiplication                     %w| T * F |
  end

  for_symbol('F') do
    getting_literals                   %w| n |
    unpacking_parenthetized_expression %w| ( E ) |
    function                           %w| Function |
  end

  for_symbol('Function') do
    evaluating_function                %w| FunctionName ( Args ) |
  end

  for_symbol('FunctionName') do
    max_function                       %w| h |
    min_function                       %w| l |
  end

  for_symbol('Args') do
    empty_args                         %w||
    single_args                        %w| E |
    concatenating_args                 %w| E , Args |
  end

end

