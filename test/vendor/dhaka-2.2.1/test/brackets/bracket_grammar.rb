class BracketGrammar < Dhaka::Grammar
  
  for_symbol(Dhaka::START_SYMBOL_NAME) do
    start                %w| Package |
  end
  
  for_symbol('Package') do
    soft_wrapped_package %w| ( Contents ) |
    cardboard_package    %w| [ Contents ] |
    wooden_package       %w| { Contents } |
  end
  
  for_symbol('Contents') do
    bracket              %w| B |
    set_of_packages      %w| SetOfPackages |
  end
    
  for_symbol('SetOfPackages') do
    one_package          %w| Package |
    multiple_packages    %w| SetOfPackages Package |
  end

end