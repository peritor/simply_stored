require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchFinderTest < Test::Unit::TestCase
  context "when finding instances" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end
 
    context "with find(:all)" do
      setup do
        User.create(:title => "Mr.")
        User.create(:title => "Mrs.")
      end
      
      should "return all instances" do  
        assert_equal 2, User.find(:all).size
      end
      
      should "allow a limit" do
        assert_equal 1, User.find(:all, :limit => 1).size
      end
      
      should "allow to order the results" do
        assert_not_equal User.find(:all).map(&:id), User.find(:all, :order => :desc).map(&:id)
        assert_equal User.find(:all).map(&:id).reverse, User.find(:all, :order => :desc).map(&:id)
      end
    end

    context "to find all instances" do
      should 'generate a default find_all view' do
        assert User.respond_to?(:all_documents)
      end
      
      should 'return all the users when calling all' do
        User.create(:title => "Mr.")
        User.create(:title => "Mrs.")
        assert_equal 2, User.all.size
      end
    end
    
    context "to find one instance" do
      should 'return one user when calling first' do
        user = User.create(:title => "Mr.")
        assert_equal user, User.first
      end
      
      should 'understand the order' do
        assert_nothing_raised do
          User.first(:order => :desc)
        end
      end
      
      should 'return nil when no user found' do
        assert_nil User.first
      end
    end
    
    context "when finding with just an identifier" do
      should "find just one instance" do
        user = User.create(:title => "Mr.")
        assert User.find(user.id).kind_of?(User)
      end
      
      should 'raise an error when no record was found' do
        assert_raises(SimplyStored::RecordNotFound) do
          User.find('abc')
        end
      end
      
      should 'tell you which class failed to load something' do
        exception = nil
        begin
          User.find('abc')
        rescue SimplyStored::RecordNotFound => e
          exception = e
        end
        assert_equal "User could not be found with \"abc\"", exception.message
      end
      
      should 'raise an error when nil was specified' do
        assert_raises(SimplyStored::Error) do
          User.find(nil)
        end
      end
      
      should 'raise an error when the record was not of the expected type' do
        post = Post.create
        assert_raises(SimplyStored::RecordNotFound) do
          User.find(post.id)
        end
      end
    end
    
    context "with a find_by prefix" do
      setup do
        recreate_db
      end
      
      should "create a view for the called finder" do
        User.find_by_name("joe")
        assert User.respond_to?(:by_name)
      end
      
      should 'not create the view when it already exists' do
        User.expects(:view).never
        User.find_by_name_and_created_at("joe", 'foo')
      end
      
      should "create a method to prevent future loops through method_missing" do
        assert !User.respond_to?(:find_by_title)
        User.find_by_title("Mr.")
        assert User.respond_to?(:find_by_title)
      end
      
      should "call the generated view and return the result" do
        user = User.create(:homepage => "http://www.peritor.com", :title => "Mr.")
        assert_equal user, User.find_by_homepage("http://www.peritor.com")
      end
      
      should 'find only one instance when using find_by' do
        User.create(:title => "Mr.")
        assert User.find_by_title("Mr.").is_a?(User)
      end
      
      should "raise an error if the parameters don't match" do
        assert_raise(ArgumentError) do
          User.find_by_title()
        end
        
        assert_raise(ArgumentError) do
          User.find_by_title(1,2,3,4,5)
        end
      end
    end
    
    context "with a find_all_by prefix" do
      should "create a view for the called finder" do
        User.find_all_by_name("joe")
        assert User.respond_to?(:by_name)
      end
      
      should 'not create the view when it already exists' do
        User.expects(:view).never
        User.find_all_by_name_and_created_at("joe", "foo")
      end
      
      should "create a method to prevent future loops through method_missing" do
        assert !User.respond_to?(:find_all_by_foo_attribute)
        User.find_all_by_foo_attribute("Mr.")
        assert User.respond_to?(:find_all_by_foo_attribute)
      end
      
      should "call the generated view and return the result" do
        user = User.create(:homepage => "http://www.peritor.com", :title => "Mr.")
        assert_equal [user], User.find_all_by_homepage("http://www.peritor.com")
      end
      
      should "return an emtpy array if none found" do
        recreate_db
        assert_equal [], User.find_all_by_title('Mr. Magoooo')
      end
      
      should 'find all instances when using find_all_by' do
        User.create(:title => "Mr.")
        User.create(:title => "Mr.")
        assert_equal 2, User.find_all_by_title("Mr.").size
      end
      
      should "raise an error if the parameters don't match" do
        assert_raise(ArgumentError) do
          User.find_all_by_title()
        end
        
        assert_raise(ArgumentError) do
          User.find_all_by_title(1,2,3,4,5)
        end
      end
    end      
  end

end
