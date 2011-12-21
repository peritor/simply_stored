require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

class DirtyTrackingTest < Test::Unit::TestCase
  context "when using dirty tracking" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end

    should "track normal properties" do
      u = User.create!(:title => 'Dr.', :name => 'Bert')
      u.name = 'Alf'
      assert u.name_changed?
      assert_equal 'Bert', u.name_was
      assert u.changed?
    end

    should "track belongs_to properties" do
      user1 = User.create!(:title => 'Dr.', :name => 'Bert')
      user2 = User.create!(:title => 'Prof.', :name => 'Jackson')
      post = Post.create!(:user => user1)
      post.user = user2
      assert post.user_changed?
      assert post.user_id_changed?
      assert_equal user1.id, post.user_id_was
      assert post.changed?
    end

    should "set foreign key properties on load" do
      user = User.create!(:title => 'Dr.', :name => 'Bert')
      post = Post.create!(:user => user)
      post = Post.find(post.id)
      assert !post.user_changed?, post.user_id_was.inspect
      assert !post.user_id_changed?
      assert !post.changed?
    end
  end
end
