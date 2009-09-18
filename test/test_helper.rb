require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'active_support'
require 'active_support/testing/assertions'

require File.expand_path(File.dirname(__FILE__) + '/../lib/simply_stored')

class Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
end