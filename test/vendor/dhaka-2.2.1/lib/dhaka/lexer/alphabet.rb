module Dhaka
  module LexerSupport
    DIGITS                  = ('0'..'9').to_a
    LOWERCASE_LETTERS       = ('a'..'z').to_a
    UPPERCASE_LETTERS       = ('A'..'Z').to_a
    LETTERS                 = LOWERCASE_LETTERS + UPPERCASE_LETTERS 
    WHITESPACE              = [" ", "\r", "\n", "\t"]
    SYMBOLS                 = %w| ~ ` ! @ # % & _ = : ; " ' < , > - |
    CLASSES                 = {'d' => DIGITS, 'w' => LETTERS, 's' => WHITESPACE}
                           
    OPERATOR_CHARACTERS     = {'(' => 'open_parenth', ')' => 'close_parenth', '[' => 'open_square_bracket', 
                              ']' => 'close_square_bracket', '+' => 'plus', '*' => 'asterisk', 
                              '?' => 'question_mark', '.' => 'period', '\\' => 'back_slash', 
                              '|' => 'pipe', '{' => 'left_curly_brace', '}' => 'right_curly_brace', 
                              '/' => 'forward_slash', '^' => 'caret', '$' => 'dollar'}

    SET_OPERATOR_CHARACTERS = %w| - ^ [ ] \\ |

    ALL_CHARACTERS          = DIGITS + LETTERS + SYMBOLS + WHITESPACE + OPERATOR_CHARACTERS.keys
  end
end
