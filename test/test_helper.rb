require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'active_support/testing/assertions'
require 'shoulda'
require 'mocha'
$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
puts File.expand_path(File.dirname(__FILE__) + "/lib")
require 'simply_stored'

class Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
  
  def recreate_db
    CouchPotato.couchrest_database.delete! rescue nil
    CouchPotato.couchrest_database.server.create_db CouchPotato::Config.database_name
  end
  
end
