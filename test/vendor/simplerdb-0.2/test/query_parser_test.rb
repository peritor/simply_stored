require "test/unit"
require 'simplerdb/query_language'

# Tests the query parser
class QueryParserTest < Test::Unit::TestCase
  
# Taken from an AWS forum post
VALID = <<END
            ['attrR' = 'random']
            ['attrR' != 'random']
            ['attrR' < 'random']
            ['attrR' <= 'random']
            ['attrR' starts-with 'random']
            ['attrR' starts-with '0000009000']
            ['attrR' = 'random1' or 'attrR' = 'random2']
            not ['attrR'='random' or 'attrR'='random']
            not ['attrR'='random']
            ['attrR1' = 'random1']  union ['attrR2' = 'random2']
            ['attrR1' = 'random1']  union ['attrR2' < 'random2']
            ['attrR1' = 'random1']  union not ['attrR2' = 'random2']
            ['attrR1' = 'random1']  intersection ['attrR2' = 'random2']
            ['attrR1' = 'random1']  intersection not ['attrR2' = 'random2']
            ['attrR1' = 'random1']  intersection ['attrR2' < 'random2']
            ['attrR1' starts-with '0000009000'] intersection ['attrR2' >= 'random2']
            ['attrR1' > '0000000100']  intersection ['attrR2' < '0000200000']  intersection ['attrR3' > '0000000200']
            ['attrR1' = 'random1']  union ['attrR2' = 'random2']   intersection ['attrR3' = 'random3']
            ['attrR1' = 'random1']  intersection ['attrR2' = 'random2']   intersection ['attrR3' = 'random3']
            ['attrR1' = 'random1']  intersection ['attrR2' = 'random2']   intersection ['attrR3' = 'random3']
            ['attrR1' = 'random1']  union ['attrR2' = 'random2']   union ['attrR3' = 'random3']
            ['attrR1' > '0000000100']  intersection ['attrR2' < '0000200000']  intersection ['attrR3' > '0000000200']
END

INVALID = <<END
            ['attrR' == 'random']
            ['attrR' - 'random']
            ['attrR' < 'random]
            ['attrR' <= 'rand'om']
            ['attrR' starts with 'random']
            ['attrR' union '0000009000']
            ['attrR' = 'random1' or 'attrR' = 'random2'] foo ['foo' = 'bar']
            []
            ['bar']
            ['']
END

  def setup
    @lexer = Dhaka::Lexer.new(SimplerDB::QueryLexerSpec)
    @parser = Dhaka::Parser.new(SimplerDB::QueryGrammar)
  end
  
  def test_valid_queries
    VALID.each do |query|
      result = @parser.parse(@lexer.lex(query.strip!))
      assert result.is_a?(Dhaka::ParseSuccessResult), query
    end
  end
  
  def test_invalid_queries
    INVALID.each do |query|
      result = @parser.parse(@lexer.lex(query.strip!))
      assert !result.is_a?(Dhaka::ParseSuccessResult), query
    end
  end
end