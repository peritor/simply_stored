class RRConflictGrammar < Dhaka::Grammar
  
  for_symbol(Dhaka::START_SYMBOL_NAME) do
    start       %w| S |
  end
  
  for_symbol('S') do
    a_expansion %w| A c d |
    b_expansion %w| B c e |
  end
  
  for_symbol('A') do
    xy          %w| x y |
  end

  for_symbol('B') do
    xy_again    %w| x y |
  end

end

