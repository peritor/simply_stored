require File.dirname(__FILE__) + "/chittagong_lexer_specification"
require File.dirname(__FILE__) + "/chittagong_evaluator"

class ChittagongDriver

  ERROR_MARKER = ">>>"
  
  def parse_error_message unexpected_token, program
    if unexpected_token.symbol_name == Dhaka::END_SYMBOL_NAME
      "Unexpected end of file."
    else
      "Unexpected token #{unexpected_token.symbol_name}:\n#{program.dup.insert(unexpected_token.input_position, ERROR_MARKER)}"
    end
  end
  
  def tokenize_error_message unexpected_char_index, program
    "Unexpected character #{program[unexpected_char_index].chr}:\n#{program.dup.insert(unexpected_char_index, ERROR_MARKER)}"
  end
  
  def evaluation_error_message evaluation_result, program
    "#{evaluation_result.exception}:\n#{program.dup.insert(evaluation_result.node.tokens[0].input_position, ERROR_MARKER)}"
  end
  
  # lipi:run_method
  def run(program)
    parse_result = ChittagongParser.parse(ChittagongLexer.lex(program))

    case parse_result
      when Dhaka::TokenizerErrorResult
        return tokenize_error_message(parse_result.unexpected_char_index, program)
      when Dhaka::ParseErrorResult
        return parse_error_message(parse_result.unexpected_token, program) 
    end
    
    evaluation_result = ChittagongEvaluator.new([{}], output_stream = []).
        evaluate(parse_result)
    if evaluation_result.exception
      return (output_stream << evaluation_error_message(evaluation_result, program)).
        join("\n") 
    end
    
    return output_stream.join("\n")
  end
  # lipi:run_method
  
end
