require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

class RetryOnErrorTest < Test::Unit::TestCase
  context "when handling connection errors" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end
    
    should "retry the save on connection error" do
      user = User.create(:name => 'Mickey Mouse', :title => "Dr.", :homepage => 'www.gmx.de')
      seq = sequence('save')
      CouchPotato.database.expects(:save_document).raises(Errno::ECONNREFUSED.new('Connection refused - connect(2)')).in_sequence(seq)
      CouchPotato.database.expects(:save_document).returns(true).in_sequence(seq)
      
      assert_nothing_raised do
        user.name = 'bert'
        assert user.save
      end      
    end
    
    should "retry the save! on connection error" do
      seq = sequence('save')
      CouchPotato.database.expects(:save_document).raises(Errno::ECONNREFUSED.new('Connection refused - connect(2)')).in_sequence(seq)
      CouchPotato.database.expects(:save_document).returns(true).in_sequence(seq)
      
      assert_nothing_raised do
        assert(user = User.create(:name => 'Mickey Mouse', :title => "Dr.", :homepage => 'www.gmx.de'))
      end      
    end
    

    should "re-raise the error if retried several times" do
      CouchPotato.database.expects(:save_document).raises(Errno::ECONNREFUSED.new('Connection refused - connect(2)')).times(3)
      
      assert_raise(Errno::ECONNREFUSED) do
        user = User.create(:name => 'Mickey Mouse', :title => "Dr.", :homepage => 'www.gmx.de')
      end
    end

  end
end
