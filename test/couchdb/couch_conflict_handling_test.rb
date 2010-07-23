require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchConflictHandlingTest < Test::Unit::TestCase
  context "when handling conflicts" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
      @original = User.create(:name => 'Mickey Mouse', :title => "Dr.", :homepage => 'www.gmx.de')
      @copy = User.find(@original.id)
      User.auto_conflict_resolution_on_save = true
    end
    
    should "be able to save without modifications" do
      assert @copy.save
    end
    
    should "be able to save when modification happen on different attributes" do
      @original.name = "Pluto"
      assert @original.save
      
      @copy.title = 'Prof.'
      assert_nothing_raised do
        assert @copy.save
      end
      
      assert_equal "Pluto", @copy.reload.name
      assert_equal "Prof.", @copy.reload.title
      assert_equal "www.gmx.de", @copy.reload.homepage
    end
    
    should "be able to save when modification happen on different, multiple attributes - remote" do
      @original.name = "Pluto"
      @original.homepage = 'www.google.com'
      assert @original.save
      
      @copy.title = 'Prof.'
      assert_nothing_raised do
        assert @copy.save
      end
      
      assert_equal "Pluto", @copy.reload.name
      assert_equal "Prof.", @copy.reload.title
      assert_equal "www.google.com", @copy.reload.homepage
    end
    
    should "be able to save when modification happen on different, multiple attributes locally" do
      @original.name = "Pluto"
      assert @original.save
      
      @copy.title = 'Prof.'
      @copy.homepage = 'www.google.com'
      assert_nothing_raised do
        assert @copy.save
      end
      
      assert_equal "Pluto", @copy.reload.name
      assert_equal "Prof.", @copy.reload.title
      assert_equal "www.google.com", @copy.reload.homepage
    end
    
    should "re-raise the conflict if there is no merge possible" do
      @original.name = "Pluto"
      assert @original.save
      
      @copy.name = 'Prof.'
      assert_raise(RestClient::Conflict) do
        assert @copy.save
      end
      
      assert_equal "Prof.", @copy.name
      assert_equal "Pluto", @copy.reload.name
    end
    
    should "re-raise the conflict if retried several times" do
      exception = RestClient::Conflict.new
      CouchPotato.database.expects(:save_document).raises(exception).times(3)
      
      @copy.name = 'Prof.'
      assert_raise(RestClient::Conflict) do
        assert @copy.save
      end
    end
    
    should "not try to merge and re-save if auto_conflict_resolution_on_save is disabled" do
      User.auto_conflict_resolution_on_save = false
      exception = RestClient::Conflict.new
      CouchPotato.database.expects(:save_document).raises(exception).times(1)
      
      @copy.name = 'Prof.'
      assert_raise(RestClient::Conflict) do
        assert @copy.save
      end
    end
  end
end
