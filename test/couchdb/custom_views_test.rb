require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CustomViewUser
  include SimplyStored::Couch
  
  property :tags
  view :by_tags, :type => SimplyStored::Couch::Views::ArrayPropertyViewSpec, :key => :tags
end

class CustomViewsTest < Test::Unit::TestCase
  
  context "Custom couch views" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end
    
    context "With array views" do
      should "find objects with one match of the array" do
        CustomViewUser.create(:tags => ["agile", "cool", "extreme"])
        CustomViewUser.create(:tags => ["agile"])
        assert_equal 2, CustomViewUser.find_all_by_tags("agile").size
      end
      
      should "find the object when the property is not an array" do
        CustomViewUser.create(:tags => "agile")
        assert_equal 1, CustomViewUser.find_all_by_tags("agile").size
        
      end
    end
  end
end
