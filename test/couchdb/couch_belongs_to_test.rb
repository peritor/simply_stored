require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchBelongsToTest < Test::Unit::TestCase
  context "with associations" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end

    context "with belongs_to" do
      should "generate a view for the association" do
        assert Post.respond_to?(:association_post_belongs_to_user)
      end

      should "raise an error if another property with the same name already exists" do
        assert_raise(RuntimeError) do
          class ::DoubleBelongsToUser
            include SimplyStored::Couch
            property :user
            belongs_to :user
          end
        end
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
  

end
