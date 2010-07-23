require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchMassAssignmentProtectionTest < Test::Unit::TestCase
  context "attribute proctection against mass assignment" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end

    context "when using attr_protected" do
      setup do
        Category.instance_eval do
          @_accessible_attributes = []
          attr_protected :parent, :alias
        end
      end
      
      should "not allow to set with mass assignment using attributes=" do
        item = Category.new
        item.attributes = {:parent => 'a', :name => 'c'}
        assert_equal 'c', item.name
        assert_nil item.parent
      end
      
      should "not allow to set with mass assignment using attributes= - ignore string vs. symbol" do
        item = Category.new
        item.attributes = {'parent' => 'a', 'name' => 'c'}
        assert_equal 'c', item.name
        assert_nil item.parent
      end
      
      should "not allow to set with mass assignment using the constructor" do
        item = Category.new(:parent => 'a', :name => 'c')
        assert_equal 'c', item.name
        assert_nil item.parent
      end
        
      should "not allow to set with mass assignment using update_attributes" do
        item = Category.new
        item.update_attributes(:parent => 'a', :name => 'c')
        assert_equal 'c', item.name
        assert_nil item.parent
      end          
    end
    
    context "attr_accessible" do
      setup do
        Category.instance_eval do
          @_protected_attributes = []
          attr_accessible :name
        end
      end
      
      should "not allow to set with mass assignment using attributes=" do
        item = Category.new
        item.attributes = {:parent => 'a', :name => 'c'}
        assert_equal 'c', item.name
        assert_nil item.parent
      end
      
      should "not allow to set with mass assignment using the constructor" do
        item = Category.new(:parent => 'a', :name => 'c')
        assert_equal 'c', item.name
        assert_nil item.parent
      end
        
      should "not allow to set with mass assignment using update_attributes" do
        item = Category.new
        item.update_attributes(:parent => 'a', :name => 'c')
        # item.reload
        assert_equal 'c', item.name
        assert_nil item.parent
      end
    end
  end
end
