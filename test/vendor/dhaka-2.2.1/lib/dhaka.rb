#--
# Copyright (c) 2006, 2007 Mushfeq Khan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'set'
require 'logger'
require 'delegate'

%w[
dot/dot
grammar/grammar_symbol
grammar/production
grammar/closure_hash
grammar/grammar
grammar/precedence
parser/parse_tree
parser/parse_result
parser/item
parser/channel
parser/parser_methods
parser/parser_state
parser/conflict
parser/token
parser/action
parser/parser_run
parser/parser
parser/compiled_parser
tokenizer/tokenizer
evaluator/evaluator
lexer/accept_actions
lexer/alphabet
lexer/regex_grammar
lexer/regex_tokenizer
lexer/regex_parser
lexer/state_machine
lexer/dfa
lexer/state
lexer/specification
lexer/lexeme
lexer/lexer_run
lexer/lexer
lexer/compiled_lexer
].each {|path| require File.join(File.dirname(__FILE__), 'dhaka/' + path)}
