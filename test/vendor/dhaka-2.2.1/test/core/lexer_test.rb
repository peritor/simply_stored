require File.dirname(__FILE__) + '/../dhaka_test_helper'

class TestLexer < Test::Unit::TestCase
  class LexerSpec < Dhaka::LexerSpecification

    for_pattern 'zz' do
      "two zs"
    end
    
    for_pattern '\w(\w|\d)*' do
      "word #{current_lexeme.value}"
    end

    # can optionally use Regexps as well
    for_pattern(/(\d)*(\.\d+)?/) do
      "number #{current_lexeme.value}"
    end
    
    for_pattern '<.*>' do
      "tag #{current_lexeme.value}"
    end

    for_pattern ' +' do
      #ignores whitespace
    end
    
    for_pattern "\n+" do
      "newline"
    end

    for_pattern "\r+" do
      "carriage return"
    end

  end
  
  def test_lexer_with_valid_input
    lexer = Dhaka::Lexer.new(LexerSpec)
    eval(lexer.compile_to_ruby_source_as(:SomeLexer))
    input = "these are words a z zz caPITALIZED word \r    
    this is a float 12.00 an integer 134 a float without a leading digit .2335 another word1"
    results =  SomeLexer.lex(input).collect
    assert_equal(
    ["word these",
     "word are",
     "word words",
     "word a",
     "word z",
     "two zs",
     "word caPITALIZED",
     "word word",
     "carriage return",
     "newline",
     "word this",
     "word is",
     "word a",
     "word float",
     "number 12.00",
     "word an",
     "word integer",
     "number 134",
     "word a",
     "word float",
     "word without",
     "word a",
     "word leading",
     "word digit",
     "number .2335",
     "word another",
     "word word1"], results[0..-2])
  end
  
  def test_lexer_with_invalid_input
    lexer = Dhaka::Lexer.new(LexerSpec)
    result = lexer.lex("this will cause an error here 123.").each do |result| 
    end
    assert(result.has_error?)
    assert_equal(34, result.unexpected_char_index)
  end

  def test_lexer_with_greedy_character_consumption
    lexer = Dhaka::Lexer.new(LexerSpec)
    results = lexer.lex("<html></html>this is a word").collect
    assert_equal(["tag <html></html>",
     "word this",
     "word is",
     "word a",
     "word word"], results[0..-2])
  end
  
  class LexerWithLookaheadsSpec < Dhaka::LexerSpecification
    
    for_pattern '\s+' do
      # ignore whitespace
    end
    
    for_pattern ':/\w+' do
      "a symbol qualifier"
    end

    for_pattern(":/[^a-zA-Z \n\r\t]*") do
      "a colon"
    end
    
    for_pattern "ab/cd" do
      "ab followed by cd: #{current_lexeme.value}"
    end
    
    for_pattern "abc/e" do
      "abc followed by e: #{current_lexeme.value}"
    end
    
    for_pattern '\w+' do
      "word #{current_lexeme.value}"
    end
    
    for_pattern '\d+' do
      "number #{current_lexeme.value}"
    end
    
  end
  
  def test_lexer_with_regexes_that_use_lookaheads
    lexer = Dhaka::Lexer.new(LexerWithLookaheadsSpec)
    eval(lexer.compile_to_ruby_source_as(:LexerWithTrickyLookaheads))
    results = LexerWithTrickyLookaheads.lex("234 : :whatever :1934 abcd ::").collect
    assert_equal(["number 234",
     "a colon",
     "a symbol qualifier",
     "word whatever",
     "a colon",
     "number 1934",
     "ab followed by cd: ab",
     "word cd",
     "a colon",
     "a colon"], results[0..-2])
  end
  
end