require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

class FinderTest < Test::Unit::TestCase
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
      context "when multiple instances exist" do
        setup do
          User.create(:title => "Mr.")
          User.create(:title => "Mrs.")
          @all = User.all
          @first = @all.first
          @last = @all.last
        end

        should 'return the first user for #find' do
          assert_equal @first, User.find(:first)
        end

        should 'return the first user for #first' do
          assert_equal @first, User.first
        end

        should 'return the last user for #find and descending order' do
          assert_equal @last, User.find(:first, :order => :desc)
        end

        should 'return the last user for #last' do
          assert_equal @last, User.last
        end
      end

      context 'When no rows exist' do
        should 'return nil for first' do
          assert_nil User.first
        end
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

    context 'The #first method' do
      should 'pass default arguments to #find' do
        User.expects(:find).with(:first)
        User.first
      end

      should 'merge passed options to #find' do
        User.expects(:find).with(:first, :limit => 2)
        User.first(:limit => 2)
      end
    end

    context 'The #last method' do
      should 'pass default arguments to #last' do
        User.expects(:find).with(:first, :order => :desc)
        User.last
      end

      should 'merge passed options to #last' do
        User.expects(:find).with(:first, :order => :desc, :limit => 2)
        User.last(:limit => 2)
      end
    end
  end

end
