require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

class CouchTest < Test::Unit::TestCase
  context "A simply stored couch instance" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
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
    
    context "when finding instances" do
      context "with find(:all)" do
        should "return all instances" do
          User.create(:title => "Mr.")
          User.create(:title => "Mrs.")
          assert_equal 2, User.find(:all).size
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
        should "create a view for the called finder" do
          User.find_by_name("joe")
          assert User.respond_to?(:by_name)
        end
        
        should 'not create the view when it already exists' do
          User.expects(:view).never
          User.find_by_name_and_created_at("joe")
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
      end
      
      context "with a find_all_by prefix" do
        should "create a view for the called finder" do
          User.find_all_by_name("joe")
          assert User.respond_to?(:by_name)
        end
        
        should 'not create the view when it already exists' do
          User.expects(:view).never
          User.find_all_by_name_and_created_at("joe")
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
        
        should 'find all instances when using find_all_by' do
          User.create(:title => "Mr.")
          User.create(:title => "Mr.")
          assert_equal 2, User.find_all_by_title("Mr.").size
        end
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

      context "with has_one" do
        
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

    context "with additional validations" do
      context "with validates_inclusion_of" do
        should "validate inclusion of an attribute in an array" do
          category = Category.new(:name => "other")
          assert !category.save
        end
      
        should "validate when the attribute is an array" do
          category = Category.new(:name => ['drinks', 'food'])
          assert_nothing_raised do
            category.save!
          end
        end
      
        should "add an error message" do
          category = Category.new(:name => "other")
          category.valid?
          assert_match(/must be one or more of food, drinks, party/, category.errors.full_messages.first)
        end
      
        should "allow blank" do
          category = Category.new(:name => nil)
          assert category.valid?
        end
      end
      
      context "with validates_format_of" do
        class ValidatedUser
          include SimplyStored::Couch
          property :name
          validates_format_of :name, :with => /Paul/
        end
        
        should 'validate the format and fail when not matched' do
          user = ValidatedUser.new(:name => "John")
          assert !user.valid?
        end
        
        should 'succeed when matched' do
          user = ValidatedUser.new(:name => "Paul")
          assert user.valid?
        end
        
        should 'fail when empty' do
          user = ValidatedUser.new(:name => nil)
          assert !user.valid?
        end
        
        context "with allow_blank" do
          class ValidatedBlankUser
            include SimplyStored::Couch
            property :name
            validates_format_of :name, :with => /Paul/, :allow_blank => true
          end
          
          should 'not fail when nil' do
            user = ValidatedBlankUser.new(:name => nil)
            assert user.valid?
          end

          should 'not fail when empty string' do
            user = ValidatedBlankUser.new(:name => '')
            assert user.valid?
          end

          should 'fail when not matching' do
            user = ValidatedBlankUser.new(:name => 'John')
            assert !user.valid?
          end

          should 'not fail when matching' do
            user = ValidatedBlankUser.new(:name => 'Paul')
            assert user.valid?
          end

        end
      end

      context "with validates_uniqueness_of" do
        should "add a view on the unique attribute" do
          assert UniqueUser.by_name
        end
        
        should "set an error when a different with the same instance exists" do
          assert UniqueUser.create(:name => "Host Master")
          user = UniqueUser.create(:name => "Host Master")
          assert !user.valid?
        end
        
        should "not have an error when we're the only one around" do
          user = UniqueUser.create(:name => "Host Master")
          assert !user.new_record?
        end
        
        should "not have an error when it's the same instance" do
          user = UniqueUser.create(:name => "Host Master")
          user = UniqueUser.find(user.id)
          assert user.valid?
        end
        
        should 'have a nice error message' do
          assert UniqueUser.create(:name => "Host Master")
          user = UniqueUser.create(:name => "Host Master")
          assert_equal "Name is already taken", user.errors.on(:name)
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
    
    context "with s3 interaction" do
      setup do
        CouchLogItem.instance_variable_set(:@_s3_connection, nil)
        
        bucket = stub(:bckt) do
          stubs(:put).returns(true)
          stubs(:get).returns(true)
        end
        
        @bucket = bucket
        
        @s3 = stub(:s3) do
          stubs(:bucket).returns(bucket)
        end
        
        RightAws::S3.stubs(:new).returns @s3
        @log_item = CouchLogItem.new
      end

      context "when saving the attachment" do
        should "fetch the collection" do
          @log_item.log_data = "Yay! It logged!"
          RightAws::S3.expects(:new).with('abcdef', 'secret!', :multi_thread => true).returns(@s3)
          @log_item.save
        end
      
        should "upload the file" do
          @log_item.log_data = "Yay! It logged!"
          @bucket.expects(:put).with(anything, "Yay! It logged!", {}, anything)
          @log_item.save
        end
      
        should "use the specified bucket" do
          @log_item.log_data = "Yay! It logged!"
          CouchLogItem._s3_options[:log_data][:bucket] = 'mybucket'
          @s3.expects(:bucket).with('mybucket').returns(@bucket)
          @log_item.save
        end
        
        should "create the bucket if it doesn't exist" do
          @log_item.log_data = "Yay! log me"
          CouchLogItem._s3_options[:log_data][:bucket] = 'mybucket'
          
          @s3.expects(:bucket).with('mybucket').returns(nil)
          @s3.expects(:bucket).with('mybucket', true, 'private').returns(@bucket)
          @log_item.save
        end
        
        should "raise an error if the bucket is not ours" do
          @log_item.log_data = "Yay! log me too"
          CouchLogItem._s3_options[:log_data][:bucket] = 'mybucket'
          
          @s3.expects(:bucket).with('mybucket').returns(nil)
          @s3.expects(:bucket).with('mybucket', true, 'private').raises(RightAws::AwsError, 'BucketAlreadyExists: The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again')
          
          assert_raise(ArgumentError) do
            @log_item.save
          end
        end
      
        should "not upload the attachment when it hasn't been changed" do
          @bucket.expects(:put).never
          @log_item.save
        end
      
        should "set the permissions to private by default" do
          class Item
            include SimplyStored::Couch
            has_s3_attachment :log_data, :bucket => 'mybucket'
          end
          @bucket.expects(:put).with(anything, anything, {}, 'private')
          @log_item = Item.new
          @log_item.log_data = 'Yay!'
          @log_item.save
        end
      
        should "set the permissions to whatever's specified in the options for the attachment" do
          @log_item.save
          old_perms = CouchLogItem._s3_options[:log_data][:permissions]
          CouchLogItem._s3_options[:log_data][:permissions] = 'public-read'
          @bucket.expects(:put).with(anything, anything, {}, 'public-read')
          @log_item.log_data = 'Yay!'
          @log_item.save
          CouchLogItem._s3_options[:log_data][:permissions] = old_perms
        end
      
        should "use the full class name and the id as key" do
          @log_item.save
          @bucket.expects(:put).with("couch_log_items/log_data/#{@log_item.id}", 'Yay!', {}, anything)
          @log_item.log_data = 'Yay!'
          @log_item.save
        end
      
        should "mark the attachment as not dirty after uploading" do
          @log_item.log_data = 'Yay!'
          @log_item.save
          assert !@log_item.instance_variable_get(:@_s3_attachments)[:log_data][:dirty]
        end
      
        should 'store the attachment when the validations succeeded' do
          @log_item.log_data = 'Yay!'
          @log_item.stubs(:valid?).returns(true)
          @bucket.expects(:put)
          @log_item.save
        end
      
        should "not store the attachment when the validations failed" do
          @log_item.log_data = 'Yay!'
          @log_item.stubs(:valid?).returns(false)
          @bucket.expects(:put).never
          @log_item.save
        end
      
        should "save the attachment status" do
          @log_item.save
          @log_item.attributes["log_data_attachments"]
        end
      
        should "save generate the url for the attachment" do
          @log_item._s3_options[:log_data][:bucket] = 'bucket-for-monsieur'
          @log_item._s3_options[:log_data][:permissions] = 'public-read'
          @log_item.save
          assert_equal "http://bucket-for-monsieur.s3.amazonaws.com/#{@log_item.s3_attachment_key(:log_data)}", @log_item.log_data_url
        end
      
        should "add a short-lived access key for private attachments" do
          @log_item._s3_options[:log_data][:permissions] = 'private'
          @log_item.save
          assert @log_item.log_data_url.include?("https://bucket-for-monsieur.s3.amazonaws.com:443/#{@log_item.s3_attachment_key(:log_data)}")
          assert @log_item.log_data_url.include?("Signature=")
          assert @log_item.log_data_url.include?("Expires=")
        end
      
        should "serialize data other than strings to json" do
          @log_item.log_data = ['one log entry', 'and another one']
          @bucket.expects(:put).with(anything, '["one log entry","and another one"]', {}, anything)
          @log_item.save
        end
      end
    
      context "when fetching the data" do
        should "fetch the data from s3 and set the attachment attribute" do
          @log_item.instance_variable_set(:@_s3_attachments, {})
          @bucket.expects(:get).with("couch_log_items/log_data/#{@log_item.id}").returns("Yay!")
          assert_equal "Yay!", @log_item.log_data
        end
      
        should "not mark the the attachment as dirty" do
          @log_item.instance_variable_set(:@_s3_attachments, {})
          @bucket.expects(:get).with("couch_log_items/log_data/#{@log_item.id}").returns("Yay!")
          @log_item.log_data
          assert !@log_item._s3_attachments[:log_data][:dirty]
        end
        
        should "not try to fetch the attachment if the value is already set" do
          @log_item.log_data = "Yay!"
          @bucket.expects(:get).never
          assert_equal "Yay!", @log_item.log_data
        end
      end
    end
    
    context "when using soft deletable" do
      should "know when it is enabled" do
        assert Hemorrhoid.soft_deleting_enabled?
        assert !User.soft_deleting_enabled?
      end
      
      should "define a :deleted_at attribute" do
        h = Hemorrhoid.new
        assert h.respond_to?(:deleted_at)
        assert h.respond_to?(:deleted_at=)
        assert_equal :deleted_at, Hemorrhoid.soft_delete_attribute
      end
      
      should "define a hard delete methods" do
        h = Hemorrhoid.new
        assert h.respond_to?(:destroy!)
        assert h.respond_to?(:delete!)
      end
      
      context "when deleting" do
        setup do
          @user = User.new(:name => 'BigT', :title => 'Dr.')
          @user.save!
          @hemorrhoid = Hemorrhoid.new
          @hemorrhoid.user = @user
          @hemorrhoid.save!
        end
        
        should "not delete the object but populate the soft_delete_attribute" do
          now = Time.now
          Time.stubs(:now).returns(now)
          assert_nil @hemorrhoid.deleted_at
          assert @hemorrhoid.delete
          assert_equal now, @hemorrhoid.deleted_at
        end
        
        should "survive reloads with the new attribute" do
          assert_nil @hemorrhoid.deleted_at
          assert @hemorrhoid.delete
          @hemorrhoid.reload
          assert_not_nil @hemorrhoid.deleted_at
        end
        
        should "know when it is deleted" do
          assert !@hemorrhoid.deleted?
          @hemorrhoid.delete
          assert @hemorrhoid.deleted?
        end
        
        should "not consider objects without soft-deleted as deleted" do
          assert !@user.deleted?
          @user.delete
          assert !@user.deleted?
        end
        
        should "not delete in DB" do
          CouchPotato.database.expects(:destroy_document).never
          @hemorrhoid.destroy
        end
        
        should "really delete if asked to" do
          CouchPotato.database.expects(:destroy_document).with(@hemorrhoid)
          @hemorrhoid.destroy!
        end
        
        context "when handling the dependent objects" do
          setup do
            @sub = SubHemorrhoid.new
            @sub.hemorrhoid = @hemorrhoid
            @sub.save!
            
            @easy_sub = EasySubHemorrhoid.new
            @easy_sub.hemorrhoid = @hemorrhoid
            @easy_sub.save!
            
            @rash = Rash.new
            @rash.hemorrhoid = @hemorrhoid
            @rash.save!
            
            @hemorrhoid.reload
          end
          
          should "delete them" do
            @hemorrhoid.delete
            @sub.reload
            assert @sub.deleted?
            assert_raise(SimplyStored::RecordNotFound) do
              EasySubHemorrhoid.find(@easy_sub.id, :with_deleted => true)
            end
            @rash = Rash.find(@rash.id)
            assert_nil @rash.hemorrhoid_id
          end
        
          should "really delete them if the parent is really deleted" do
            @hemorrhoid.delete!
            assert_raise(SimplyStored::RecordNotFound) do
              EasySubHemorrhoid.find(@sub.id, :with_deleted => true)
            end
            
            assert_raise(SimplyStored::RecordNotFound) do
              EasySubHemorrhoid.find(@easy_sub.id, :with_deleted => true)
            end
            
            @rash = Rash.find(@rash.id)
            assert_nil @rash.hemorrhoid_id
          end
        end
        
      end
      
      context "when loading" do
        setup do
          @user = User.new(:name => 'BigT', :title => 'Dr.')
          @user.save!
          @hemorrhoid = Hemorrhoid.new
          @hemorrhoid.user = @user
          @hemorrhoid.save!
        end
        
        context "by id" do
          should "not be found by default" do
            @hemorrhoid.destroy            
            assert_raise(SimplyStored::RecordNotFound) do
              Hemorrhoid.find(@hemorrhoid.id)
            end
          end
          
          should "be found if supplied with :with_deleted" do
            @hemorrhoid.destroy
            
            assert_not_nil Hemorrhoid.find(@hemorrhoid.id, :with_deleted => true)
          end
          
          should "not be found if it is really gone" do
            old_id = @hemorrhoid.id
            @hemorrhoid.destroy!
            
            assert_raise(SimplyStored::RecordNotFound) do
              Hemorrhoid.find(old_id)
            end
          end
          
          should "always reload" do
            @hemorrhoid.destroy
            assert_nothing_raised do
              @hemorrhoid.reload
            end
            assert_not_nil @hemorrhoid.deleted_at
          end
        end
        
        context "by relation" do
          should "not load deleted by default"
          should "load deleted if asked to"
        end
      end
    end
    
  end
end
