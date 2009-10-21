class LALRButNotSLRGrammar < Dhaka::Grammar

  for_symbol(Dhaka::START_SYMBOL_NAME) do
    start %w| E |
  end

  for_symbol('E') do
    E_Aa  %w| A a |
    E_bAc %w| b A c |
    E_dc  %w| d c |
    E_bda %w| b d a |
  end

  for_symbol('A') do
    A_d   %w| d |
  end

end

