class MalformedGrammar < Dhaka::Grammar

  for_symbol('foo') do
    bar %w| baz |
  end
  
end
