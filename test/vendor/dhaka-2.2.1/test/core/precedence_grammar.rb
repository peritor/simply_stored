class PrecedenceGrammar < Dhaka::Grammar

  precedences do
    left       %w| * |
  end
  
  for_symbol(Dhaka::START_SYMBOL_NAME) do
    expression %w| E * F |
    whatever   %w| E F |, :prec => '*'
  end
  
  for_symbol('F') do
    something  %w| foo |
  end

end
    