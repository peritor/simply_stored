#!/usr/bin/env ruby
Dir['**/*test.rb'].each do |test_file|
  puts test_file
  require File.join(File.dirname(__FILE__), test_file)
end