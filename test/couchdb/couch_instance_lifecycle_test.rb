require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchTest < Test::Unit::TestCase
  context "A simply stored couch instance" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end
    
    context "design documents" do
      should "delete all" do
        db = "http://127.0.0.1:5984/#{CouchPotato::Config.database_name}"
        assert_equal 0, SimplyStored::Couch.delete_all_design_documents(db)
        user = User.create
        Post.create(:user => user)
        user.posts
        assert_equal 1, SimplyStored::Couch.delete_all_design_documents(db)
      end
    end

    context "when creating instances" do
      should "populate the attributes" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        assert_equal "Mr.", user.title
        assert_equal "Host Master", user.name
      end
      
      should "save the instance" do
        user = User.create(:title => "Mr.")
        assert !user.new_record?
      end
      
      context "with a bang" do
        should 'not raise an exception when saving succeeded' do
          assert_nothing_raised do
            User.create!(:title => "Mr.")
          end
        end
        
        should 'save the user' do
          user = User.create!(:title => "Mr.")
          assert !user.new_record?
        end
        
        should 'raise an error when the validations failed' do
          assert_raises(CouchPotato::Database::ValidationsFailedError) do
            User.create!(:title => nil)
          end
        end
      end
      
      context "with a block" do
        should 'call the block with the record' do
          user = User.create do |u|
            u.title = "Mr."
          end
          
          assert_equal "Mr.", user.title
        end
        
        should 'save the record' do
          user = User.create do |u|
            u.title = "Mr."
          end
          assert !user.new_record?
        end
        
        should 'assign attributes via the hash' do
          user = User.create(:title => "Mr.") do |u|
            u.name = "Host Master"
          end
          
          assert_equal "Mr.", user.title
          assert_equal "Host Master", user.name
        end
      end
    end
    
    context "when saving an instance" do
      should "um, save the instance" do
        user = User.new(:title => "Mr.")
        assert user.new_record?
        user.save
        assert !user.new_record?
      end
      
      context "when using save!" do
        should 'raise an exception when a validation isnt fulfilled' do
          user = User.new
          assert_raises(CouchPotato::Database::ValidationsFailedError) do
            user.save!
          end
        end
      end
      
      context "when using save(false)" do
        should "not run the validations" do
          user = User.new
          user.save(false)
          assert !user.new?
          assert !user.dirty?
        end
      end
    end
    
    context "when destroying an instance" do
      should "remove the instance" do
        user = User.create(:title => "Mr")
        assert_difference 'User.find(:all).size', -1 do
          user.destroy
        end
      end
      
      should 'return the frozen instance, brrrr' do
        user = User.create(:title => "Mr")
        assert_equal user, user.destroy
      end
    end
    
    context "when updating attributes" do
      should "merge in the updated attributes" do
        user = User.create(:title => "Mr.")
        user.update_attributes(:title => "Mrs.")
        assert_equal "Mrs.", user.title
      end
      
      should "save the instance" do
        user = User.create(:title => "Mr.")
        user.update_attributes(:title => "Mrs.")
        assert !user.dirty?
      end
    end
    
   
    context "when counting" do
      setup do
        recreate_db
      end
      
      context "when counting all" do
        should "return the number of objects in the database" do
          CountMe.create(:title => "Mr.")
          CountMe.create(:title => "Mrs.")
          assert_equal 2, CountMe.find(:all).size
          assert_equal 2, CountMe.count
        end
        
        should "only count the correct class" do
          CountMe.create(:title => "Mr.")
          DontCountMe.create(:title => 'Foo')
          assert_equal 1, CountMe.find(:all).size
          assert_equal 1, CountMe.count
        end
      end
      
      context "when counting by prefix" do
        should "return the number of matching objects" do
          CountMe.create(:title => "Mr.")
          CountMe.create(:title => "Mrs.")
          assert_equal 1, CountMe.find_all_by_title('Mr.').size
          assert_equal 1, CountMe.count_by_title('Mr.')
        end
        
        should "only count the correct class" do
          CountMe.create(:title => "Mr.")
          DontCountMe.create(:title => 'Mr.')
          assert_equal 1, CountMe.find_all_by_title('Mr.').size
          assert_equal 1, CountMe.count_by_title('Mr.')
        end
      end
    end

    context "when reloading an instance" do
      should "reload new attributes from the database" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        user2 = User.find(user.id)
        user2.update_attributes(:title => "Mrs.", :name => "Hostess Masteress")
        user.reload
        assert_equal "Mrs.", user.title
        assert_equal "Hostess Masteress", user.name
      end
      
      should "remove attributes that are no longer in the database" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        assert_not_nil user.name
        same_user_in_different_thread = User.find(user.id)
        same_user_in_different_thread.name = nil
        same_user_in_different_thread.save!
        assert_nil user.reload.name
      end
      
      should "also remove foreign key attributes that are no longer in the database" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        post = Post.create(:user => user)
        assert_not_nil post.user_id
        same_post_in_different_thread = Post.find(post.id)
        same_post_in_different_thread.user = nil
        same_post_in_different_thread.save!
        assert_nil post.reload.user_id
      end
      
      should "not be dirty after reloading" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        user2 = User.find(user.id)
        user2.update_attributes(:title => "Mrs.", :name => "Hostess Masteress")
        user.reload
        assert !user.dirty?
      end
      
      should "ensure that association caches for has_many are cleared" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        post = Post.create(:user => user)
        assert_equal 1, user.posts.size
        assert_not_nil user.instance_variable_get("@posts")
        user.reload
        assert_nil user.instance_variable_get("@posts")
        assert_not_nil user.posts.first
      end
      
      should "ensure that association caches for belongs_to are cleared" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        post = Post.create(:user => user)
        post.user
        assert_not_nil post.instance_variable_get("@user")
        post.reload
        assert_nil post.instance_variable_get("@user")
        assert_not_nil post.user
      end
      
      should "update the revision" do
        user = User.create(:title => "Mr.", :name => "Host Master")
        user2 = User.find(user.id)
        user2.update_attributes(:title => "Mrs.", :name => "Hostess Masteress")
        user.reload
        assert_equal user._rev, user2._rev
      end
    end
  end
end
