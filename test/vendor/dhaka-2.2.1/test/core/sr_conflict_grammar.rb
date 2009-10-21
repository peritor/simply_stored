class SRConflictGrammar < Dhaka::Grammar

  for_symbol(Dhaka::START_SYMBOL_NAME) do
    statement              %w| statement |
  end

  for_symbol('statement') do
    if_statement           %w| if_statement |
  end

  for_symbol('if_statement') do
    if_then_statement      %w| IF expr THEN statement |
    if_then_else_statement %w| IF expr THEN statement ELSE statement END |
  end
  
end
