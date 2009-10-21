class ArithmeticPrecedenceLexerSpecification < Dhaka::LexerSpecification
  
  for_pattern '\s' do
    # ignore whitespace
  end
  
  %w| - h l , |.each do |char|
    for_pattern char do
      create_token(char)
    end
  end
  
  %w| ( ) + / * ^ |.each do |char|
    for_pattern "\\#{char}" do
      create_token(char)
    end
  end
  
  for_pattern '\d+' do
    create_token('n')
  end

end