class NullableGrammar < Dhaka::Grammar

  for_symbol(Dhaka::START_SYMBOL_NAME) do
    tuple                     %w| Tuple |
  end

  for_symbol('Tuple') do
    element_list              %w| ( Elements ) |
  end

  for_symbol('Elements') do
    empty_element_list        %w| |
    concatenate_element_lists %w| Character Elements |
  end

  for_symbol('Character') do
    literal_a                 %w| a |
    literal_b                 %w| b |
  end

end