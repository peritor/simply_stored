require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'active_support'
require 'active_support/testing/assertions'
$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
puts File.expand_path(File.dirname(__FILE__) + "/lib")
require 'simply_stored/couch'
require 'simply_stored/simpledb'

$:.<< File.expand_path(File.dirname(__FILE__) + "/vendor/simplerdb-0.2/lib")
$:.<< File.expand_path(File.dirname(__FILE__) + "/vendor/dhaka-2.2.1/lib")

class Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
  
  def recreate_db
    CouchPotato.couchrest_database.delete! rescue nil
    CouchPotato.couchrest_database.server.create_db CouchPotato::Config.database_name
  end
  
end
