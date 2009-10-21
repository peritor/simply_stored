module ArithmeticTestMethods
  def parse(token_stream)
    CompiledArithmeticParser.parse(token_stream)
  end
  
  def token(symbol_name, value)
    Dhaka::Token.new(symbol_name, value, nil)
  end
end