class SimpleGrammar < Dhaka::Grammar
  
  for_symbol(Dhaka::START_SYMBOL_NAME) do
    start                    %w| S # |
  end
  
  for_symbol('S') do
    expression               %w| E |
  end
  
  for_symbol('E') do
    subtraction              %w| E - T |
    term                     %w| T |
  end
    
  for_symbol('T') do
    literal                  %w| n |
    parenthetized_expression %w| ( E ) |
  end

end

