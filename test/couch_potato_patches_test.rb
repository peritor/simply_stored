require File.expand_path(File.dirname(__FILE__) + "/test_helper")
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

class CouchPotatoPatchesTest < Test::Unit::TestCase
  context "With a patched CouchPotato" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end
    
    context "when creating with validate options" do
      should "not run the validations when saved with false" do
        category = Category.new
        CouchPotato.database.save_document(category, false)
        assert !category.new?
      end
      
      should "run the validations when saved with true" do
        category = Category.new
        CouchPotato.database.save_document(category, true)
        assert category.new?
      end
      
      should "run the validations when saved with default" do
        category = Category.new
        CouchPotato.database.save_document(category)
        assert category.new?
      end
    end
    
    context "when updating with validate options" do
      should "not run the validations when saved with false" do
        category = Category.create(:name => 'food')
        assert !category.new?
        category.name = 'other'
        CouchPotato.database.save_document(category, false)
        assert !category.dirty?
      end
      
      should "run the validations when saved with true" do
        category = Category.create(:name => "food")
        assert !category.new?
        category.name = 'other'
        CouchPotato.database.save_document(category, true)
        assert category.dirty?
        assert !category.valid?
      end
      
      should "run the validations when saved with default" do
        category = Category.create(:name => "food")
        assert !category.new?
        category.name = 'other'
        CouchPotato.database.save_document(category)
        assert category.dirty?
      end
    end
    
  end
end