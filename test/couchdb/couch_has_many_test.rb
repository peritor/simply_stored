require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchHasManyTest < Test::Unit::TestCase
  context "has_many" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
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
      
      context "limit" do
      
        should "be able to limit the result set" do
          user = User.create(:title => "Mr.")
          3.times {
            post = Post.new
            post.user = user
            post.save!
          }
          assert_equal 2, user.posts(:limit => 2).size
        end
      
        should "use the given options in the cache-key" do
          user = User.create(:title => "Mr.")
          3.times {
            post = Post.new
            post.user = user
            post.save!
          }
          assert_equal 2, user.posts(:limit => 2).size
          assert_equal 3, user.posts(:limit => 3).size
        end
      
        should "be able to limit the result set - also for through objects" do
          @user = User.create(:title => "Mr.")
          first_pain = Pain.create
          frist_hemorrhoid = Hemorrhoid.create(:user => @user, :pain => first_pain)
          assert_equal [first_pain], @user.pains          
          second_pain = Pain.create
          second_hemorrhoid = Hemorrhoid.create(:user => @user, :pain => second_pain)
          @user.reload
          assert_equal 2, @user.pains.size
          assert_equal 1, @user.pains(:limit => 1).size
        end
      end
      
      context "order" do
        setup do
          @user = User.create(:title => "Mr.")
          3.times {
            post = Post.new
            post.user = @user
            post.save!
          }
        end
        
        should "support different order" do
          assert_nothing_raised do
            @user.posts(:order => :asc)
          end
          
          assert_nothing_raised do
            @user.posts(:order => :desc)
          end
        end
        
        should "reverse the order if :desc" do
          assert_equal @user.posts(:order => :asc).map(&:id).reverse, @user.posts(:order => :desc).map(&:id)
        end
        
        should "work with the limit option" do
          last_post = Post.create(:user => @user)
          assert_not_equal @user.posts(:order => :asc, :limit => 3).map(&:id).reverse, @user.posts(:order => :desc, :limit => 3).map(&:id)
        end
      end
              
      should "verify the given options for the accessor method" do
        user = User.create(:title => "Mr.")
        assert_raise(ArgumentError) do
          user.posts(:foo => false)
        end
      end
      
      should "verify the given options for the association defintion" do
        assert_raise(ArgumentError) do
          User.instance_eval do
            has_many :foo, :bar => :do
          end
        end
      end
      
      should "only fetch objects of the correct type" do
        user = User.create(:title => "Mr.")
        post = Post.new
        post.user = user
        post.save!
        
        comment = Comment.new
        comment.user = user
        comment.save!
        
        assert_equal 1, user.posts.size
      end
      
      should "getter should user cache" do
        user = User.create(:title => "Mr.")
        post = Post.new
        post.user = user
        post.save!
        user.posts
        assert_equal [post], user.instance_variable_get("@posts")[:all]
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
          assert_equal [item], daddy.instance_variable_get("@posts")[:all]
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
          assert_equal [], user.instance_variable_get("@posts")[:all]
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
        
        should "delete the object when dependent:destroy" do
          Category.instance_eval do
            has_many :tags, :dependent => :destroy
          end
          
          category = Category.create(:name => "food")
          tag = Tag.create(:name => "food", :category => category)
          assert !tag.new?
          category.remove_tag(tag)
          
          assert_equal [], Tag.find(:all)
        end
        
        should "not nullify or delete dependents if the options is set to :ignore when removing" do
          master = Master.create
          master_id = master.id
          servant = Servant.create(:master => master)
          master.remove_servant(servant)
          assert_equal master_id, servant.reload.master_id
        end
        
        should "not nullify or delete dependents if the options is set to :ignore when deleting" do
          master = Master.create
          master_id = master.id
          servant = Servant.create(:master => master)
          master.destroy
          assert_equal master_id, servant.reload.master_id
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
          assert_equal [], user.instance_variable_get("@posts")[:all]
        end
        
        context "when counting" do
          setup do
            @user = User.create(:title => "Mr.")
          end
          
          should "define a count method" do
            assert @user.respond_to?(:post_count)
          end
          
          should "cache the result" do
            assert_equal 0, @user.post_count
            Post.create(:user => @user)
            assert_equal 0, @user.post_count
            assert_equal 0, @user.instance_variable_get("@post_count")
            @user.instance_variable_set("@post_count", nil)
            assert_equal 1, @user.post_count
          end
          
          should "force reload even if cached" do
            assert_equal 0, @user.post_count
            Post.create(:user => @user)
            assert_equal 0, @user.post_count
            assert_equal 1, @user.post_count(:force_reload => true)
          end
          
          should "count the number of belongs_to objects" do
            assert_equal 0, @user.post_count(:force_reload => true)
            Post.create(:user => @user)
            assert_equal 1, @user.post_count(:force_reload => true)
            Post.create(:user => @user)
            assert_equal 2, @user.post_count(:force_reload => true)
          end
          
          should "not count foreign objects" do
            assert_equal 0, @user.post_count
            Post.create(:user => nil)
            Post.create(:user => User.create(:title => 'Doc'))
            assert_equal 0, @user.post_count
            assert_equal 2, Post.count
          end
          
          should "not count delete objects" do
            hemorrhoid = Hemorrhoid.create(:user => @user)
            assert_equal 1, @user.hemorrhoid_count
            hemorrhoid.delete
            assert_equal 0, @user.hemorrhoid_count(:force_reload => true)
            assert_equal 1, @user.hemorrhoid_count(:force_reload => true, :with_deleted => true)
          end
          
          should "work with has_many :through" do
            assert_equal 0, @user.pain_count
            first_pain = Pain.create
            frist_hemorrhoid = Hemorrhoid.create(:user => @user, :pain => first_pain)
            assert_equal [first_pain], @user.pains
            assert_equal 1, @user.pain_count(:force_reload => true)
            
            second_pain = Pain.create
            second_hemorrhoid = Hemorrhoid.create(:user => @user, :pain => second_pain)
            assert_equal 2, @user.pain_count(:force_reload => true)
          end
          
        end
      end
      
      context 'when destroying the parent objects' do
        should "delete relations when dependent is destroy" do
          Category.instance_eval do
            has_many :tags, :dependent => :destroy
          end
        
          category = Category.create(:name => "food")
          tag = Tag.create(:name => "food", :category => category)
        
          assert_equal [tag], Tag.find(:all)
          category.destroy
          assert_equal [], Tag.find(:all)
        end
      
        should "nullify relations when dependent is nullify" do
        
          user = User.create(:title => "Mr.")
          post = Post.create(:user => user)
        
          user.destroy
          post = Post.find(post.id)
          assert_nil post.user_id
        end
        
        should "nullify the foreign key even if validation forbids" do
          user = User.create(:title => "Mr.")
          post = StrictPost.create(:user => user)

          user.destroy
          post = StrictPost.find(post.id)
          assert_nil post.user_id
        end
      end
    end
    
    context "with has_many :trough" do
      setup do
        @journal_1 = Journal.create
        @journal_2 = Journal.create
        @reader_1 = Reader.create
        @reader_2 = Reader.create
      end
      
      should "raise an exception if there is no :through relation" do
        
        assert_raise(ArgumentError) do
          class FooHasManyThroughBar
            include SimplyStored::Couch
            has_many :foos, :through => :bars
          end
        end
      end
      
      should "define a getter" do
        assert @journal_1.respond_to?(:readers)
        assert @reader_1.respond_to?(:journals)
      end
        
      should "load the objects through" do
        membership = Membership.new
        membership.journal = @journal_1
        membership.reader = @reader_1
        assert membership.save
        
        assert_equal @journal_1, membership.journal
        assert_equal @reader_1, membership.reader
        assert_equal [membership], @journal_1.reload.memberships
        assert_equal [membership], @journal_1.reload.memberships
        
        assert_equal [@reader_1], @journal_1.readers
        assert_equal [@journal_1], @reader_1.journals
        
        membership_2 = Membership.new
        membership_2.journal = @journal_1
        membership_2.reader = @reader_2
        assert membership_2.save
        
        assert_equal [@reader_1.id, @reader_2.id].sort, @journal_1.reload.readers.map(&:id).sort
        assert_equal [@journal_1.id], @reader_1.reload.journals.map(&:id).sort
        assert_equal [@journal_1.id], @reader_2.reload.journals.map(&:id).sort
        
        membership_3 = Membership.new
        membership_3.journal = @journal_2
        membership_3.reader = @reader_2
        assert membership_3.save
        
        assert_equal [@reader_1.id, @reader_2.id].sort, @journal_1.reload.readers.map(&:id).sort
        assert_equal [@reader_2.id].sort, @journal_2.reload.readers.map(&:id).sort
        assert_equal [@journal_1.id], @reader_1.reload.journals.map(&:id).sort
        assert_equal [@journal_1.id, @journal_2.id].sort, @reader_2.reload.journals.map(&:id).sort
        
        membership_3.destroy
        
        assert_equal [@reader_1.id, @reader_2.id].sort, @journal_1.reload.readers.map(&:id).sort
        assert_equal [], @journal_2.reload.readers
        assert_equal [@journal_1.id], @reader_1.reload.journals.map(&:id).sort
        assert_equal [@journal_1.id], @reader_2.reload.journals.map(&:id).sort
      end
      
      should "verify the given options" do
        assert_raise(ArgumentError) do
          @journal_1.readers(:foo => true)
        end
      end
      
      should "not try to destroy/nullify through-objects on parent object delete" do
        membership = Membership.new
        membership.journal = @journal_1
        membership.reader = @reader_1
        assert membership.save
        
        @reader_1.reload
        @journal_1.reload
        
        Reader.any_instance.expects("journal=").never
        Journal.any_instance.expects(:readers).never

        @journal_1.delete
      end
    end
  end
end
