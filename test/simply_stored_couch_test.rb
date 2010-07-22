require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

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

    context "with associations" do
      context "with belongs_to" do
        should "generate a view for the association" do
          assert Post.respond_to?(:association_post_belongs_to_user)
        end
        
        should "add the foreign key id to the referencing object" do
          user = User.create(:title => "Mr.")
          post = Post.create(:user => user)
          
          post = Post.find(post.id)
          assert_equal user.id, post.user_id
        end
        
        should "set also the foreign key id to nil if setting the referencing object to nil" do
          user = User.create(:title => "Mr.")
          post = Post.create(:user => user)
          post.user = nil
          post.save!
          assert_nil post.reload.user
          assert_nil post.reload.user_id
        end
        
        should "fetch the object from the database when requested through the getter" do
          user = User.create(:title => "Mr.")
          post = Post.create(:user => user)
          
          post = Post.find(post.id)
          assert_equal user, post.user
        end
        
        should "mark the referencing object as dirty" do
          user = User.create(:title => "Mr.")
          post = Post.create
          post.user = user
          assert post.dirty?
        end
        
        should "allow assigning a different object and store the id accordingly" do
          user = User.create(:title => "Mr.")
          user2 = User.create(:title => "Mrs.")
          post = Post.create(:user => user)
          post.user = user2
          post.save
          
          post = Post.find(post.id)
          assert_equal user2, post.user
        end
        
        should "check the class and raise an error if not matching in belongs_to setter" do
          post = Post.create
          assert_raise(ArgumentError, 'expected Post got String') do
            post.user = 'foo'
          end
        end
        
        should 'not query for the object twice in getter' do
          user = User.create(:title => "Mr.")
          post = Post.create(:user => user)
          post = Post.find(post.id)
          User.expects(:find).returns "user"
          post.user
          User.expects(:find).never
          post.user
        end
        
        should 'use cache in getter' do
          post = Post.create
          post.instance_variable_set("@user", 'foo')
          assert_equal 'foo', post.user
        end
        
        should "ignore the cache if force_reload is given as an option" do
          user = User.create(:name => 'Dude', :title => 'Mr.')
          post = Post.create(:user => user)
          post.reload
          post.instance_variable_set("@user", 'foo')
          assert_not_equal 'foo', post.user(:force_reload => true)
        end
        
        should 'set cache in setter' do
          post = Post.create
          user = User.create
          assert_nil post.instance_variable_get("@user")
          post.user = user
          assert_equal user, post.instance_variable_get("@user")
        end

        should "not hit the database when the id column is empty" do
          User.expects(:find).never
          post = Post.create
          post.user
        end

        should "know when the associated object changed" do
          post = Post.create(:user => User.create(:title => "Mr."))
          user2 = User.create(:title => "Mr.")
          post.user = user2
          assert post.user_changed?
        end
        
        should "not be changed when an association has not changed" do
          post = Post.create(:user => User.create(:title => "Mr."))
          assert !post.user_changed?
        end
        
        should "not be changed when assigned the same object" do
          user = User.create(:title => "Mr.")
          post = Post.create(:user => user)
          post.user = user
          assert !post.user_changed?
        end
        
        should "not be changed after saving" do
          user = User.create(:title => "Mr.")
          post = Post.new
          post.user = user
          assert post.user_changed?
          post.save!
          assert !post.user_changed?
        end
        
        should "handle a foreign_key of '' as nil" do
          post = Post.create
          post.user_id = ''
          
          assert_nothing_raised do
            assert_nil post.user
          end
        end
        
        context "with aliased associations" do
          should "allow different names for the same class" do
            editor = User.create(:name => 'Editor', :title => 'Dr.')
            author = User.create(:name => 'author', :title => 'Dr.')
            assert_not_nil editor.id, editor.errors.inspect
            assert_not_nil author.id, author.errors.inspect
            
            doc = Document.create(:editor => editor, :author => author)
            doc.save!
            assert_equal editor.id, doc.editor_id
            assert_equal author.id, doc.author_id
            doc = Document.find(doc.id)
            assert_not_nil doc.editor, doc.inspect
            assert_not_nil doc.author
            assert_equal editor.id, doc.editor.id
            assert_equal author.id, doc.author.id
          end
        end
      end
    end

    context "attribute proctection against mass assignment" do
      
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
