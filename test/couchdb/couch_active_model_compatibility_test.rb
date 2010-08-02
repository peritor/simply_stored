require File.dirname(__FILE__) + '/../test_helper'

begin
  require 'active_model'

  class CouchModel
    include SimplyStored::Couch
    property :name
    validates_presence_of :name
  end

  class CouchActiveModelCompatibilityTest < Test::Unit::TestCase
    def setup
      @model = CouchModel.new
    end
    include ActiveModel::Lint::Tests
  end

rescue LoadError
  puts "ActiveModel not installed, skipping lint tests."
end


