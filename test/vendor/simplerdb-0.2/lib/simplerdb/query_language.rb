require 'rubygems'
require 'dhaka'
require 'set'

module SimplerDB
  # Uses the lexer/parser/evaluator to perform the query and do simple paging
  class QueryExecutor
    ERROR_MARKER = ">>>"
  
    def initialize
      @lexer = Dhaka::Lexer.new(QueryLexerSpec)
      @parser = Dhaka::Parser.new(QueryGrammar)
    end
    
    # Execute the query
    def do_query(query, domain, max = 100, token = 0)
      parse_result = @parser.parse(@lexer.lex(query))
      token = 0 if token.nil?
      
      case parse_result
        when Dhaka::TokenizerErrorResult
          raise tokenize_error_message(parse_result.unexpected_char_index, query)
        when Dhaka::ParseErrorResult
          raise parse_error_message(parse_result.unexpected_token, query) 
      end
  
      items = QueryEvaluator.new(domain).evaluate(parse_result)
      results = []
      count = 0
      items.each do |item|
        break if results.size == max
        results << item if count >= token
        count += 1
      end
      
      if (count == items.size)
        return results,nil
      else
        return results,count
      end
    end
    
    # From dhaka examples
    def parse_error_message(unexpected_token, program)
      if unexpected_token.symbol_name == Dhaka::END_SYMBOL_NAME
        "Unexpected end of file."
      else
        "Unexpected token #{unexpected_token.symbol_name}:\n#{program.dup.insert(unexpected_token.input_position - 1, ERROR_MARKER)}"
      end
    end
    
    def tokenize_error_message(unexpected_char_index, program)
      "Unexpected character #{program[unexpected_char_index - 1].chr}:\n#{program.dup.insert(unexpected_char_index - 1, ERROR_MARKER)}"
    end
    
    def evaluation_error_message(evaluation_result, program)
      "#{evaluation_result.exception}:\n#{program.dup.insert(evaluation_result.node.tokens[0].input_position, ERROR_MARKER)}"
    end
  
  end
  
  # The SimpleDB query language grammar, as defined at
  # http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/SDB_API_Query.html
  class QueryGrammar < Dhaka::Grammar
    for_symbol(Dhaka::START_SYMBOL_NAME) do
      start                %w| predicates |
    end
  
    for_symbol('predicates') do
      single_predicate     %w| predicate |
      not_predicate        %w| not predicate |
      intersection         %w| predicate intersection predicates |
      not_intersection     %w| not predicate intersection predicates |
      union                %w| predicate union predicates |
      not_union            %w| not predicate union predicates |
    end
    
    for_symbol('predicate') do
      attribute_comparison %w| [ attribute_comparison ] |
    end
    
    for_symbol('attribute_comparison') do
      single_comparison    %w| identifier comp_op constant |
      not_comparison       %w| not identifier comp_op constant |
      and_comparison       %w| identifier comp_op constant and attribute_comparison |
      not_and_comparison   %w| not identifier comp_op constant and attribute_comparison |
      or_comparison        %w| identifier comp_op constant or attribute_comparison |
      not_or_comparison    %w| not identifier comp_op constant or attribute_comparison |
    end
    
    for_symbol('comp_op') do
      equal                %w| = |
      greater_than         %w| > |
      less_than            %w| < |
      greater_or_equal     %w| >= |
      less_or_equal        %w| <= |
      not_equal            %w| != |
      starts_with          %w| starts-with |
    end
    
    for_symbol('identifier') do
      identifier           %w| quoted_string |
    end
    
    for_symbol('constant') do
      constant            %w| quoted_string |
    end
  
  end
  
  # The lexer for the query language.
  class QueryLexerSpec < Dhaka::LexerSpecification
    
    %w| = > < >= <= != starts-with |.each do |op|
      for_pattern(op) do
        create_token(op)
      end
    end
    
    for_pattern('\[') do
      create_token('[')
    end
    
    for_pattern('\]') do
      create_token(']')
    end
    
    for_pattern('\s+') do
      # ignore whitespace
    end
    
    KEYWORDS = %w| not and or union intersection |
    KEYWORDS.each do |keyword|
      for_pattern(keyword) do
        create_token(keyword)
      end
    end
    
    for_pattern("'(\\\\'|[^'])+'") do
      create_token 'quoted_string'
    end
    
  end
  
  # The query evaluator. This class acts on the parse tree and will return
  # a list of item names that match the query from the evaluate method.
  class QueryEvaluator < Dhaka::Evaluator
    self.grammar = QueryGrammar
    
    def initialize(domain = nil)
      @domain = domain
      @predicate_identifier = nil
      @all_items = nil
    end
    
    define_evaluation_rules do
     
      for_single_predicate do
        evaluate(child_nodes[0])
      end
      
      for_not_predicate do
        results = evaluate(child_nodes[1])
        all_items.difference(results)
      end
      
      for_intersection do
        results = evaluate(child_nodes[0])
        results.intersection(evaluate(child_nodes[2]))
      end
      
      # TODO Nots are probably not handled correctly. Need to play with AWS to find out for sure.
      for_not_intersection do
        results = evaluate(child_nodes[1])
        all_items.difference(results.intersection(evaluate(child_nodes[3])))
      end
      
      for_union do
        results = evaluate(child_nodes[0])
        results.union(evaluate(child_nodes[2]))
      end
      
      for_not_union do
        results = evaluate(child_nodes[1])
        all_items.difference(results.union(evaluate(child_nodes[3])))
      end
      
      for_attribute_comparison do
        evaluate(child_nodes[1])
      end
      
      for_single_comparison do
        do_comparison(evaluate(child_nodes[0]), evaluate(child_nodes[1]), evaluate(child_nodes[2]))
      end
      
      for_not_comparison do
        do_comparison(evaluate(child_nodes[1]), evaluate(child_nodes[2]), evaluate(child_nodes[3]), true)
      end
      
      for_and_comparison do
        results = do_comparison(evaluate(child_nodes[0]), evaluate(child_nodes[1]), evaluate(child_nodes[2]))
        results.intersection(evaluate(child_nodes[4]))
      end
      
      for_not_and_comparison do
        results = do_comparison(evaluate(child_nodes[1]), evaluate(child_nodes[2]), evaluate(child_nodes[3]), true)
        results.intersection(evaluate(child_nodes[5]))
      end
      
      for_or_comparison do
        results = do_comparison(evaluate(child_nodes[0]), evaluate(child_nodes[1]), evaluate(child_nodes[2]))
        results.union(evaluate(child_nodes[4]))
      end
      
      for_not_or_comparison do
        results = do_comparison(evaluate(child_nodes[1]), evaluate(child_nodes[2]), evaluate(child_nodes[3]), true)
        results.union(evaluate(child_nodes[5]))
      end
      
      for_equal { lambda { |v1, v2| v1 == v2 } }
      for_greater_than { lambda { |v1, v2| v1 > v2 } }
      for_less_than { lambda { |v1, v2| v1 < v2 } }
      for_greater_or_equal { lambda { |v1, v2| v1 >= v2 } }
      for_less_or_equal { lambda { |v1, v2| v1 <= v2 } }
      # TODO ['a1' != 'v2'] should return false if a1 has values v1 AND v2
      for_not_equal { lambda { |v1, v2| v1 != v2 } }
      for_starts_with { lambda { |v1, v2| v2[0...v1.length] == v1 } }
      
      for_identifier { val(child_nodes[0]) }
      for_constant { val(child_nodes[0]) }
    end
  
    def val(node)
      node.token.value.to_s[1..-2]
    end
  
    def all_items
      unless @all_items
        @all_items = @domain.items.collect { |k,v| k }.to_set
      end
      
      return @all_items
    end
  
    # Apply the given comparison params to every item in the domain
    def do_comparison(identifier, op, constant, negate = false)  
      results = Set.new
      
      if @domain
        @domain.items.each_value do |item|
          attrs = item.attributes[identifier]
          
          attrs.each do |attr|
            match = op.call(constant, attr.value)
            if (match && !negate) || (negate && !match)
              results << item
              break
            end
          end
        end
      end
      
      results
    end
  end
end