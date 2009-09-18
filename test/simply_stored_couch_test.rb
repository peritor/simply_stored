require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

class CouchTest < Test::Unit::TestCase
  context "A simply stored couch instance" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      User.find(:all).each(&:destroy)
      Post.find(:all).each(&:destroy)
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
    end
    
    context "when destroying an instance" do
      should "remove the instance" do
        user = User.create(:title => "Mr")
        assert_difference 'User.find(:all).size', -1 do
          user.destroy
        end
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
    
    context "when finding instances" do
      context "when find(:all)" do
        should "return all instances" do
          User.create(:title => "Mr.")
          User.create(:title => "Mrs.")
          assert_equal 2, User.find(:all).size
        end
      end
      
      context "when finding with just an identifier" do
        should "find just one instance" do
          user = User.create(:title => "Mr.")
          assert User.find(user.id).kind_of?(User)
        end
      end
      
      context "with a find_by prefix" do
        should "create a view for the called finder" do
          User.find_by_name("joe")
          assert User.respond_to?(:by_name)
        end
        
        should "create a method to prevent future loops through method_missing" do
          assert !User.respond_to?(:find_by_title)
          User.find_by_title("Mr.")
          assert User.respond_to?(:find_by_title)
        end
        
        should "call the generated view" do
          assert_difference 'User.find_by_homepage("http://www.peritor.com").size' do
            User.create(:homepage => "http://www.peritor.com", :title => "Mr.")
          end
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
          post.save
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

      end
      
      context "with has_many" do
        should "create a fetch method for the associated objects" do
          user = User.new
          assert user.respond_to?(:posts)
        end
        
        should "fetch the associated objects" do
          user = User.create(:title => "Mr.")
          3.times {
            post = Post.new
            post.user = user
            post.save!
          }
          assert_equal 3, user.posts.size
          user.posts
        end
        
        should "getter should user cache" do
          user = User.create(:title => "Mr.")
          post = Post.new
          post.user = user
          post.save!
          user.posts
          assert_equal [post], user.instance_variable_get("@posts")
        end
        
        should "add methods to handle associated objects" do
          user = User.new(:title => "Mr.")
          assert user.respond_to?(:add_post)
          assert user.respond_to?(:remove_post)
          assert user.respond_to?(:remove_all_posts)
        end
        
        should 'ignore the cache when requesting explicit reload' do
          user = User.create(:title => "Mr.")
          assert_equal [], user.posts
          post = Post.new
          post.user = user
          post.save!
          assert_equal [post], user.posts(:force_reload => true)
        end
        
        context "when adding items" do
          should "add the item to the internal cache" do
            daddy = User.new(:title => "Mr.")
            item = Post.new
            assert_equal [], daddy.posts
            daddy.add_post(item)
            assert_equal [item], daddy.posts
            assert_equal [item], daddy.instance_variable_get("@posts")
          end

          should "raise an error when the added item is not an object of the expected class" do
            user = User.new
            assert_raise(ArgumentError, 'excepted Post got String') do
              user.add_post('foo')
            end
          end
        
          should "save the added item" do
            post = Post.new
            user = User.create(:title => "Mr.")
            user.add_post(post)
            assert !post.new_record?
          end
        
          should 'set the forein key on the added object' do
            post = Post.new
            user = User.create(:title => "Mr.")
            user.add_post(post)
            assert_equal user.id, post.user_id
          end
        end
        
        context "when removing items" do
          should "should unset the foreign key" do
            user = User.create(:title => "Mr.")
            post = Post.create(:user => user)

            user.remove_post(post)
            assert_nil post.user_id
          end
          
          should "remove the item from the cache" do
            user = User.create(:title => "Mr.")
            post = Post.create(:user => user)
            assert user.posts.include?(post)
            user.remove_post(post)
            assert !user.posts.any?{|p| post.id == p.id}
            assert_equal [], user.instance_variable_get("@posts")
          end
          
          should "save the removed item with the nullified foreign key" do
            user = User.create(:title => "Mr.")
            post = Post.create(:user => user)

            user.remove_post(post)
            post = Post.find(post.id)
            assert_nil post.user_id
          end
          
          should 'raise an error when another object is the owner of the object to be removed' do
            user = User.create(:title => "Mr.")
            mrs = User.create(:title => "Mrs.")
            post = Post.create(:user => user)
            assert_raise(ArgumentError) do
              mrs.remove_post(post)
            end
          end
          
          should 'raise an error when the object is the wrong type' do
            user = User.new
            assert_raise(ArgumentError, 'excepted Post got String') do
              user.remove_post('foo')
            end
          end
        end
        
        context "when removing all items" do
          should 'nullify the foreign keys on all referenced items' do
            user = User.create(:title => "Mr.")
            post = Post.create(:user => user)
            post2 = Post.create(:user => user)
            user.remove_all_posts
            post = Post.find(post.id)
            post2 = Post.find(post2.id)
            assert_nil post.user_id
            assert_nil post2.user_id
          end
          
          should 'empty the cache' do
            user = User.create(:title => "Mr.")
            post = Post.create(:user => user)
            post2 = Post.create(:user => user)
            user.remove_all_posts
            assert_equal [], user.posts
            assert_equal [], user.instance_variable_get("@posts")
          end
        end
      end
    end

    context "with additional validations" do
      should "validate inclusion of an attribute in an array" do
        category = Category.new(:name => "other")
        assert !category.save
      end
      
      should "add an error message" do
        category = Category.new(:name => "other")
        category.valid?
        assert_match(/must be one of food, drinks, party/, category.errors.full_messages.first)
      end
    end
  end
end
