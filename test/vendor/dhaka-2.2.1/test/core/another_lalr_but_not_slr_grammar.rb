require File.dirname(__FILE__)+'/../dhaka_test_helper'

class AnotherLALRButNotSLRGrammar < Dhaka::Grammar

  for_symbol(Dhaka::START_SYMBOL_NAME) do
    assignment %w| L = R |
    rhs        %w| R |
  end

  for_symbol('L') do
    contents   %w| * R |
    identifier %w| id |
  end

  for_symbol('R') do
    l_value    %w| L |
  end

end

