require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchValidationsTest < Test::Unit::TestCase
  context "with additional validations" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end

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
      
      should 'create a view to check with' do
        assert UniqueUser.respond_to?(:by_name)
        assert_equal :name, UniqueUser.by_name.send(:options)[:key]
      end

      should 'not overwrite the view when a custom one already exists' do
        assert_equal :email, UniqueUserWithAView.by_name.send(:options)[:key]
      end
    end
  end
end
