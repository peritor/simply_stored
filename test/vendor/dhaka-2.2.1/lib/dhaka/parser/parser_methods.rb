#!/usr/bin/env ruby
module Dhaka
  # This module is included both in Parser and CompiledParser. 
  module ParserMethods
    # +token_stream+ is an Enumerable of Token-s. Returns either a ParseSuccessResult or a ParseErrorResult. 
    def parse token_stream
      parser_run = ParserRun.new(grammar, start_state, token_stream)
      parser_run.run
    end
  end
end