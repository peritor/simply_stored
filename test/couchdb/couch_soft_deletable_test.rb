require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchSoftDeletableTest < Test::Unit::TestCase
  context "when using soft deletable" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end
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
      
      context "callbacks" do
      
        should "still fire the callbacks" do
          @hemorrhoid = Hemorrhoid.create
          $before = nil
          $after = nil
          def @hemorrhoid.before_destroy_callback
            $before = "now"
          end
        
          def @hemorrhoid.after_destroy_callback
            $after = "now"
          end
        
          @hemorrhoid.destroy
        
          assert_not_nil $before
          assert_not_nil $after
        end
      
        should "not fire the callbacks on the real destroy if the object is already deleted" do
          @hemorrhoid = Hemorrhoid.create
          def @hemorrhoid.before_destroy_callback
            raise "Callback called even though #{skip_callbacks.inspect}"
          end
        
          def @hemorrhoid.after_destroy_callback
            raise "Callback called even though #{skip_callbacks.inspect}"
          end
        
          def @hemorrhoid.deleted?
            true
          end
          
          assert_nothing_raised do
            @hemorrhoid.destroy!
          end
        end
        
        should "not fire the callbacks on the real destroy if the object is not deleted" do
          @hemorrhoid = Hemorrhoid.create
          $before = nil
          $after = nil
          def @hemorrhoid.before_destroy_callback
            $before = "now"
          end
        
          def @hemorrhoid.after_destroy_callback
            $after = "now"
          end
        
          @hemorrhoid.destroy!
        
          assert_not_nil $before
          assert_not_nil $after
        end
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
        
        should "not nullify dependents if they are soft-deletable" do
          small_rash = SmallRash.create(:hemorrhoid => @hemorrhoid)
          @hemorrhoid.reload
          @hemorrhoid.destroy
          small_rash = SmallRash.find(small_rash.id)
          assert_not_nil small_rash.hemorrhoid_id
          assert_equal @hemorrhoid.id, small_rash.hemorrhoid_id
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
      
      context "all" do
        setup do
          recreate_db
          @hemorrhoid = Hemorrhoid.create
          assert @hemorrhoid.destroy
          assert @hemorrhoid.reload.deleted?
        end
        
        should "not load deleted" do
          assert_equal [], Hemorrhoid.find(:all)
          assert_equal [], Hemorrhoid.find(:all, :with_deleted => false)
        end
        
        should "load non-deleted" do
          hemorrhoid = Hemorrhoid.create
          assert_not_equal [], Hemorrhoid.find(:all)
          assert_not_equal [], Hemorrhoid.find(:all, :with_deleted => false)
        end
        
        should "load deleted if asked to" do
          assert_equal [@hemorrhoid.id], Hemorrhoid.find(:all, :with_deleted => true).map(&:id)
        end
      end
      
      context "first" do
        setup do
          recreate_db
          @hemorrhoid = Hemorrhoid.create
          assert @hemorrhoid.destroy
          assert @hemorrhoid.reload.deleted?
        end
        
        should "not load deleted" do
          assert_nil Hemorrhoid.find(:first)
          assert_nil Hemorrhoid.find(:first, :with_deleted => false)
        end
        
        should "load non-deleted" do
          hemorrhoid = Hemorrhoid.create
          assert_not_nil Hemorrhoid.find(:first)
          assert_not_nil Hemorrhoid.find(:first, :with_deleted => false)
        end
        
        should "load deleted if asked to" do
          assert_equal @hemorrhoid, Hemorrhoid.find(:first, :with_deleted => true)
        end
      end
      
      context "find_by and find_all_by" do
        setup do
          recreate_db
          @hemorrhoid = Hemorrhoid.create(:nickname => 'Claas', :size => 3)
          @hemorrhoid.destroy
        end
        
        context "find_by" do
          should "not load deleted" do
            assert_nil Hemorrhoid.find_by_nickname('Claas')
            assert_nil Hemorrhoid.find_by_nickname('Claas', :with_deleted => false)
            
            assert_nil Hemorrhoid.find_by_nickname_and_size('Claas', 3)
            assert_nil Hemorrhoid.find_by_nickname_and_size('Claas', 3, :with_deleted => false)
          end
          
          should "load non-deleted" do
            hemorrhoid = Hemorrhoid.create(:nickname => 'OtherNick', :size => 3)
            assert_equal hemorrhoid.id, Hemorrhoid.find_by_nickname('OtherNick', :with_deleted => true).id
            assert_equal hemorrhoid.id, Hemorrhoid.find_by_nickname('OtherNick').id
          end
        
          should "load deleted if asked to" do
            assert_not_nil Hemorrhoid.find_by_nickname('Claas', :with_deleted => true)
            assert_equal @hemorrhoid.id, Hemorrhoid.find_by_nickname('Claas', :with_deleted => true).id
            
            assert_not_nil Hemorrhoid.find_by_nickname_and_size('Claas', 3, :with_deleted => true)
            assert_equal @hemorrhoid.id, Hemorrhoid.find_by_nickname_and_size('Claas', 3, :with_deleted => true).id
          end
        end
        
        context "find_all_by" do
          should "not load deleted" do
            assert_equal [], Hemorrhoid.find_all_by_nickname('Claas')
            assert_equal [], Hemorrhoid.find_all_by_nickname('Claas', :with_deleted => false)
            
            assert_equal [], Hemorrhoid.find_all_by_nickname_and_size('Claas', 3)
            assert_equal [], Hemorrhoid.find_all_by_nickname_and_size('Claas', 3, :with_deleted => false)
          end
          
          should "load non-deleted" do
            hemorrhoid = Hemorrhoid.create(:nickname => 'Lampe', :size => 4)
            assert_equal [hemorrhoid.id], Hemorrhoid.find_all_by_nickname('Lampe').map(&:id)
          end
        
          should "load deleted if asked to" do
            assert_equal [@hemorrhoid.id], Hemorrhoid.find_all_by_nickname('Claas', :with_deleted => true).map(&:id)
            assert_equal [@hemorrhoid.id], Hemorrhoid.find_all_by_nickname_and_size('Claas', 3, :with_deleted => true).map(&:id)
          end
        end
        
        should "reuse the same view - when find_all_by is called first" do
          assert_equal [], Hemorrhoid.find_all_by_nickname('Claas')
          assert_nil Hemorrhoid.find_by_nickname('Claas')
        end
        
        should "reuse the same view - when find_by is called first" do
          assert_nil Hemorrhoid.find_by_nickname('Claas')
          assert_equal [], Hemorrhoid.find_all_by_nickname('Claas')
        end
      end
      
      context "by relation" do
        setup do
          @hemorrhoid.destroy
        end
        
        context "has_many" do
          should "not load deleted by default" do
            assert_equal [], @user.hemorrhoids
          end
        
          should "load deleted if asked to" do
            assert_equal [@hemorrhoid.id], @user.hemorrhoids(:with_deleted => true).map(&:id)
          end
        end
        
        context "has_many :through" do
          setup do
            @user = User.create(:name => 'BigT', :title => 'Dr.')
            @pain = Pain.create
            
            @hemorrhoid = Hemorrhoid.new
            @hemorrhoid.user = @user
            @hemorrhoid.pain = @pain
            @hemorrhoid.save!
            
            @hemorrhoid.destroy
          end
          
          should "not load deleted by default" do
            assert_equal [], @user.pains
          end
        
          should "load deleted if asked to" do
            assert_equal [@pain.id], @user.pains(:with_deleted => true).map(&:id)
          end
        end
        
        context "has_one" do
          setup do
            @spot = Spot.create
            
            @hemorrhoid = Hemorrhoid.new
            @hemorrhoid.spot = @spot
            @hemorrhoid.save!
            
            @hemorrhoid.destroy
          end
          
          should "not load deleted by default" do
            assert_nil @spot.hemorrhoid
          end
        
          should "load deleted if asked to" do
            assert_equal @hemorrhoid.id, @spot.hemorrhoid(:with_deleted => true).id
          end
        end
        
        context "belongs_to" do
          setup do              
            @hemorrhoid = Hemorrhoid.new
            @hemorrhoid.save!
            
            @sub = SubHemorrhoid.new
            @sub.hemorrhoid = @hemorrhoid
            @sub.save!
            
            @hemorrhoid.destroy
          end
          
          should "not load deleted by default" do
            @sub.reload
            assert_raise(SimplyStored::RecordNotFound) do
              assert_nil @sub.hemorrhoid
            end
          end
        
          should "load deleted if asked to" do
            @sub.reload
            assert_equal @hemorrhoid.id, @sub.hemorrhoid(:with_deleted => true).id
          end
        end
        
      end
      
    end
    
    context "when counting" do
      setup do
        @hemorrhoid = Hemorrhoid.create(:nickname => 'Claas')
        assert @hemorrhoid.destroy
        assert @hemorrhoid.reload.deleted?
      end
      
      should "not count deleted" do
        assert_equal 0, Hemorrhoid.count
        assert_equal 0, Hemorrhoid.count(:with_deleted => false)
      end
      
      should "count non-deleted" do
        hemorrhoid = Hemorrhoid.create(:nickname => 'Claas')
        assert_equal 1, Hemorrhoid.count
        assert_equal 1, Hemorrhoid.count(:with_deleted => false)
      end
      
      should "count deleted if asked to" do
        assert_equal 1, Hemorrhoid.count(:with_deleted => true)
      end      
      
      context "count_by" do
        should "not count deleted" do
          assert_equal 0, Hemorrhoid.count_by_nickname('Claas')
          assert_equal 0, Hemorrhoid.count_by_nickname('Claas', :with_deleted => false)
        end

        should "count deleted if asked to" do
          assert_equal 1, Hemorrhoid.count_by_nickname('Claas', :with_deleted => true)
        end
      end  
    end
  end
end
