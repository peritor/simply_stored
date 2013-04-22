require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')
require 'pry'

class Paginator < Test::Unit::TestCase
  context "pagination on model" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
      50.times { PaginatedUser.create }
    end

    context "when per_page is missing" do
      should "return 10 items" do
        assert_equal PaginatedUser.build_pagination.all.count, 10
        assert_equal PaginatedUser.build_pagination(:page => 2).all.count, 10
      end

    end

    context "when per_page is given" do
      should "return items as per_page" do
        assert_equal PaginatedUser.build_pagination(:per_page => 13).all.count, 13
        assert_equal PaginatedUser.build_pagination(:page => 2, :per_page => 16).all.count, 16
      end
    end

    context "when per_page more than number of total items" do
      should "return items as per_page" do
        assert_equal PaginatedUser.build_pagination(:per_page => 100).all.count, 0
        assert_equal PaginatedUser.build_pagination(:page => 2, :per_page => 99).all.count, 0
      end
    end

  end

  context "pagination on has_many association" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
      @paginated_user = PaginatedUser.create(:name => "Ashish")
      50.times { PaginatedArticle.create(:paginated_user => @paginated_user) }
    end

    context "when no pagination parameters given" do
      should "return all items" do
        assert_equal @paginated_user.paginated_articles.count, 50
      end
    end

    context "when per_page is not given" do
      should "return all items" do
        assert_equal @paginated_user.paginated_articles(:page => 1).count, 50
      end
    end


    context "when per_page is given" do
      should "return all items" do
        assert_equal @paginated_user.paginated_articles(:page => 1, :per_page => 10).count, 10
        assert_equal @paginated_user.paginated_articles(:page => 3, :per_page => 10).count, 10
        assert_equal @paginated_user.paginated_articles(:per_page => 10).count, 10
      end
    end

    context "when per_page is greater than total number of items" do
      should "return no items" do
        assert_equal @paginated_user.paginated_articles(:page => 1, :per_page => 101).count, 0
      end
    end  

    context "when page is out of range" do
      should "return no items" do
        assert_equal @paginated_user.paginated_articles(:page => 1000, :per_page => 10).count, 0  
      end
    end  

  end
end
