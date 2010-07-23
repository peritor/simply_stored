require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchHasOneTest < Test::Unit::TestCase
  context "with has_one" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end
    
    should "add a getter method" do
      assert Instance.new.respond_to?(:identity)
    end
    
    should "fetch the object when invoking the getter" do
      instance = Instance.create
      identity = Identity.create(:instance => instance)
      assert_equal identity, instance.identity
    end
    
    should "verify the given options for the accessor method" do
      instance = Instance.create
      assert_raise(ArgumentError) do
        instance.identity(:foo => :var)
      end
    end
    
    should "verify the given options for the association defintion" do
      assert_raise(ArgumentError) do
        User.instance_eval do
          has_one :foo, :bar => :do
        end
      end
    end
    
    should "store the fetched object into the cache" do
      instance = Instance.create
      identity = Identity.create(:instance => instance)
      instance.identity
      assert_equal identity, instance.instance_variable_get("@identity")
    end
    
    should "not fetch from the database when object is in cache" do
      instance = Instance.create
      identity = Identity.create(:instance => instance)
      instance.identity
      CouchPotato.database.expects(:view).never
      instance.identity
    end
    
    should "update the foreign object to have the owner's id in the forein key" do
      instance = Instance.create
      identity = Identity.create
      instance.identity = identity
      identity.reload
      assert_equal instance.id, identity.instance_id
    end
    
    should "update the cache when setting" do
      instance = Instance.create
      identity = Identity.create
      instance.identity = identity
      CouchPotato.expects(:database).never
      assert_equal identity, instance.identity
    end
    
    should "set the foreign key value to nil when assigning nil" do
      instance = Instance.create
      identity = Identity.create(:instance => instance)
      instance.identity = nil
      identity = Identity.find(identity.id)
      assert_nil identity.instance_id
    end
    
    should 'check the class' do
      instance = Instance.create
      assert_raise(ArgumentError, 'expected Item got String') do
        instance.identity = 'foo'
      end
    end
    
    should 'delete the dependent objects when dependent is set to destroy' do
      identity = Identity.create
      mag = Magazine.create
      mag.identity = identity
      mag.identity = nil
      assert_nil Identity.find_by_id(identity.id)
    end
    
    should 'unset the id on the foreign object when a new object is set' do
      instance = Instance.create
      identity = Identity.create(:instance => instance)
      identity2 = Identity.create
      
      instance.identity = identity2
      identity = Identity.find(identity.id)
      assert_nil identity.instance_id
    end
    
    should 'delete the foreign object when a new object is set and dependent is set to destroy' do
      identity = Identity.create
      identity2 = Identity.create
      mag = Magazine.create
      mag.identity = identity
      mag.identity = identity2
      assert_nil Identity.find_by_id(identity.id)
    end
    
    should 'delete the foreign object when parent is destroyed and dependent is set to destroy' do
      identity = Identity.create
      mag = Magazine.create
      mag.identity = identity
      
      mag.destroy
      assert_nil Identity.find_by_id(identity.id)
    end
    
    should 'nullify the foreign objects foreign key when parent is destroyed' do
      identity = Identity.create
      instance = Instance.create
      instance.identity = identity
      instance.destroy
      identity = Identity.find(identity.id)
      assert_nil identity.instance_id
    end
  end
end
