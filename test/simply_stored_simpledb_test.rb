require File.expand_path(File.dirname(__FILE__) + "/test_helper")

require File.dirname(__FILE__) + "/fixtures/simpledb/item_daddy.rb"
require File.dirname(__FILE__) + "/fixtures/simpledb/item.rb"
require File.dirname(__FILE__) + "/fixtures/simpledb/namespace_foo.rb"
require File.dirname(__FILE__) + "/fixtures/simpledb/namespace_bar.rb"
require File.dirname(__FILE__) + "/fixtures/simpledb/log_item.rb"
require File.dirname(__FILE__) + "/fixtures/simpledb/protected_item.rb"

require 'simplerdb/server'
old_stderr = $stderr
$stderr = File.open("/dev/null","w")

$server ||= SimplerDB::Server.new(8087)
$thread ||= Thread.new do
  trap(:INT) {
    exit
  }
  $server.start
end

$stderr = old_stderr


class SimplyStoredTest < Test::Unit::TestCase
  context "The simply stored base class" do
    setup do
      ItemDaddy.instance_eval do
        has_one :item, :clear => :nullify
      end
    
      ItemDaddy.instance_eval do
        has_many :items, :clear => :nullify
      end
    
      SimplyStored::Simple.aws_access_key = 'foo'
      SimplyStored::Simple.aws_secret_access_key = 'bar'
      RightAws::ActiveSdb.establish_connection(SimplyStored::Simple.aws_access_key, SimplyStored::Simple.aws_secret_access_key, :server => 'localhost', :port => '8087', :protocol => 'http', :logger => Logger.new('/dev/null'))
      Item.create_domain
      ItemDaddy.create_domain
      Namespace::Foo.create_domain
      Namespace::Bar.create_domain
      LogItem.create_domain
      ProtectedItem.create_domain
      @item = Item.new(:foo_attribute => 'a', :bar_attribute_array => 'goog')
    end
    
    should "use UUIDTools::UUID.random_create to generate the ID" do
      UUIDTools::UUID.expects(:random_create).returns('foo')
      item = create_item
      assert_equal 'foo', item.id
    end
    
    context "attributes" do
      should "set the given attributes" do
        @item.set_attributes(:foo_attribute => '99', :bar_attribute_array => ['1', '2', '3'])
        assert_equal '99', @item.foo_attribute
        assert_equal ['1', '2', '3'], @item.bar_attribute_array
      end
      
      should "not nil the other attributes" do
        @item.bar_attribute_array = ['99']
        @item.set_attributes(:foo_attribute => '66')
        assert_equal ['99'], @item.bar_attribute_array
      end
    end
    
    context "simpledb getter and setter" do
    
      should "simpledb_attribute_getter" do
        assert @item.respond_to?(:foo_attribute)
        @item['foo_attribute'] = 'abc'
        assert_equal 'abc', @item.foo_attribute
      end
    
      should "getter when empty" do
        @item['bar_attribute_array'] = []
        @item['foo_attribute'] = nil
        assert_equal nil, @item.foo_attribute
        assert_equal [], @item.bar_attribute_array
      end
    
      should "getter when empty after setting using the setter" do
        @item.bar_attribute_array = []
        @item.foo_attribute = nil
        assert_equal nil, @item.foo_attribute
        assert_equal [], @item.bar_attribute_array
      end
    
      should "attribute setter" do
        assert @item.respond_to?(:foo_attribute=)
        @item.foo_attribute = 5
        assert_equal 5, @item['foo_attribute'].first
        assert_equal 5, @item.foo_attribute
      end
    
      should "attribute definition adds to internal attribute list" do
        ['foo_attribute', 'item_daddy_id', 'bar_attribute_array', 'updated_at', 'created_at', 'integer_field'].each do |attr|
          assert @item.class.instance_variable_get("@_defined_attributes").include?(attr)
        end
      end
    
      should "array_getter" do
        assert @item.respond_to?(:bar_attribute_array)
        @item['bar_attribute_array'] = ['abc']
        assert_equal ['abc'], @item.bar_attribute_array
      end
    
      should "array_setter" do
        assert @item.respond_to?(:bar_attribute_array=)
        @item.bar_attribute_array = 5
        assert_equal [5], @item['bar_attribute_array']
        assert_equal [5], @item.bar_attribute_array
    
        @item.bar_attribute_array << 7
        assert_equal [5,7], @item.bar_attribute_array
      end
    
      should "array_setter when given an empty array" do
        @item['bar_attribute_array'] = []
        assert_equal [], @item.bar_attribute_array
        @item.bar_attribute_array << 7
        assert_equal [7], @item.bar_attribute_array
    
        @item.bar_attribute_array << 11
        assert_equal [7,11], @item.bar_attribute_array
      end
      
      context "belongs_to" do
      
        should "getter" do
          assert @item.respond_to?(:item_daddy)
    
          @item[:item_daddy_id] = 'the_id_of_item'
          ItemDaddy.expects(:find).with('the_id_of_item', {:auto_load => true}).returns('foo')
          assert_equal 'foo', @item.item_daddy
        end
    
        should "setter" do
          assert @item.respond_to?(:item_daddy=)
    
          item_daddy = ItemDaddy.new
          item_daddy.expects(:id).returns('item_daddy_id')
          @item.expects(:item_daddy_id=).with('item_daddy_id')
    
          @item.item_daddy = item_daddy
        end
    
        should "check the class when setting" do
          assert_raise(ArgumentError, 'expected ItemDaddy got String') do
            @item.item_daddy = 'foo'
          end
        end
    
        should "use the cache when getting" do
          @item[:item_daddy_id] = 'the_id_of_item'
          ItemDaddy.expects(:find).with('the_id_of_item', {:auto_load => true}).returns('foo').times(1)
          assert_equal 'foo', @item.item_daddy
          assert_equal 'foo', @item.item_daddy
        end
    
        should "set the cache when setting" do
          @item.instance_variable_set("@_cached_belongs_to_item_daddy", 'foo')
          assert_equal 'foo', @item.item_daddy
    
          daddy = ItemDaddy.new('id' => 'the-ID')
          @item.expects(:item_daddy_id=)
          @item.expects(:instance_variable_set).with("@_cached_belongs_to_item_daddy", daddy)
    
          @item.item_daddy = daddy
        end
        
        should "not hit the database when the id column is empty" do
          ItemDaddy.expects(:find).never
          @item.item_daddy_id = []
          @item.item_daddy
        end
      end
      
      context "has_one" do
      
        should "getter" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          assert daddy.respond_to?(:item)
    
          Item.expects(:send).with(:find_by_item_daddy_id, 'daddy_id', {:auto_load => true}).returns('a')
          assert_equal 'a', daddy.item
        end
    
        should "use the cache when getting" do
          daddy = ItemDaddy.new(:id => 'daddy_id')    
          Item.expects(:send).with(:find_by_item_daddy_id, 'daddy_id', {:auto_load => true}).returns('a').times(1)
          assert_equal 'a', daddy.item
          assert_equal 'a', daddy.item
          assert_equal 'a', daddy.item
        end
    
        should "setter" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          assert daddy.respond_to?(:item=)
          item = Item.new
          item.expects(:item_daddy_id=).with('daddy_id')
    
          daddy.item = item
        end
    
        should "set the cache when setting" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          item = Item.new
          item.expects(:item_daddy_id=).with('daddy_id')
    
          daddy.item = item
          assert_equal item, daddy.instance_variable_get("@_cached_has_one_item")
        end
    
        should "check the class" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          assert_raise(ArgumentError, 'expected Item got String') do
            daddy.item = 'foo'
          end
        end
    
        should "clear relations when depending:nullify" do
    
          ItemDaddy.instance_eval do
            has_one :item, :clear => :nullify
          end
    
          daddy = ItemDaddy.new(:id => 'daddy_id')
          old_item = Item.new
          old_item.stubs(:item_daddy_id).returns('daddy_id')
          old_item.expects(:item_daddy_id=).with(nil)
          daddy.expects(:item).returns(old_item)
    
          new_item = Item.new
          new_item.stubs(:item_daddy_id=)
          daddy.item = new_item
        end
    
        should "delete relations when depending:destroy" do
    
          ItemDaddy.instance_eval do
            has_one :item, :clear => :destroy
          end
    
          daddy = ItemDaddy.new(:id => 'daddy_id')
          old_item = Item.new
          old_item.stubs(:item_daddy_id).returns('daddy_id')
          old_item.expects(:delete)
          daddy.expects(:item).returns(old_item)
    
          new_item = Item.new
          new_item.stubs(:item_daddy_id=)
          daddy.item = new_item
        end
        
      end
      
      context "has_many" do
    
        should "getter" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          assert daddy.respond_to?(:items)
    
          Item.expects(:send).with(:find_all_by_item_daddy_id, 'daddy_id', {:auto_load => true}).returns(['a'])
          assert_equal ['a'], daddy.items
        end
    
        should "use the cache when getting" do
          daddy = ItemDaddy.new(:id => 'daddy_id')    
          Item.expects(:send).with(:find_all_by_item_daddy_id, 'daddy_id', {:auto_load => true}).returns(['a']).times(1)
          assert_equal ['a'], daddy.items
          assert_equal ['a'], daddy.items
          assert_equal ['a'], daddy.items
        end
    
        should "setter" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          assert daddy.respond_to?(:add_item)
          assert daddy.respond_to?(:remove_item)
          assert daddy.respond_to?(:remove_all_items)
        end
    
        should "add_item" do
          daddy = ItemDaddy.new(:id => 'daddy_id_')
          item = Item.new
          item.expects(:item_daddy_id=).with('daddy_id_')
    
          assert_equal [], daddy.items
          daddy.add_item(item)
          assert_equal [item], daddy.items
          assert_equal [item], daddy.instance_variable_get("@_cached_has_many_items")
        end
    
        should "check the class when using add_item" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          assert_raise(ArgumentError, 'excepted Item got String') do
            daddy.add_item('foo')
          end
        end
    
        should "save when adding an item" do
          @item.expects(:save).with(false)
    
          daddy = ItemDaddy.new(:id => 'daddy_id')
          daddy.add_item(@item)
        end
    
        should "remove an item" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          item = Item.new
          item.expects(:item_daddy_id=).with(nil)
          item.expects(:item_daddy_id).returns('daddy_id')
          item.expects(:save).with(false)
    
          daddy.instance_variable_set("@_cached_has_many_items", [item])
          assert_equal [item], daddy.items
          daddy.remove_item(item)
          assert_equal [], daddy.items
          assert_equal [], daddy.instance_variable_get("@_cached_has_many_items")
        end
    
        should "check ownership when removing" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          my_item = Item.new
          my_item.expects(:item_daddy_id=).with(nil)
          my_item.expects(:item_daddy_id).returns('daddy_id')
    
          other_item = Item.new
          other_item.expects(:item_daddy_id=).never
          other_item.expects(:item_daddy_id).returns('not_daddys_id')
    
          assert_nothing_raised do
            daddy.remove_item(my_item)
          end
    
          assert_raise(ArgumentError, 'cannot remove as not mine') do
            daddy.remove_item(other_item)
          end
        end
    
        should "remove all items" do
          daddy = ItemDaddy.new(:id => 'daddy_id')
          item_1 = Item.new
          item_1.expects(:item_daddy_id).returns('daddy_id')
          item_1.expects(:item_daddy_id=).with(nil)
          item_2 = Item.new
          item_2.expects(:item_daddy_id).returns('daddy_id')
          item_2.expects(:item_daddy_id=).with(nil)
    
          Item.expects(:find_all_by_item_daddy_id).with('daddy_id').returns([item_1, item_2])
    
          daddy.remove_all_items
    
          assert_equal [], daddy.instance_variable_get("@_cached_has_many_items")
        end
    
        should "delete relations if depending:destroy" do
          ItemDaddy.instance_eval do
            has_many :items, :clear => :destroy
          end
    
          daddy = ItemDaddy.new(:id => 'daddy_id')
          item = Item.new
          item.expects(:delete)
          item.expects(:item_daddy_id).returns('daddy_id')
    
          daddy.remove_item(item)
          assert_equal [], daddy.instance_variable_get("@_cached_has_many_items")
        end

      end
    end
    
    context "attribute proctection against mass assignment" do
      
      context "when using attr_protected" do
        setup do
          ProtectedItem.instance_eval do
            @_accessible_attributes ||= []
            attr_protected :a, :b
          end
        end
        
        should "not allow to set with mass assignment using attributes=" do
          item = ProtectedItem.new
          item.attributes = {:a => 'a', :c => 'c'}
          assert_equal 'c', item.c
          assert_nil item.a
        end
        
        should "not allow to set with mass assignment using attributes= - ignore string vs. symbol" do
          item = ProtectedItem.new
          item.attributes = {'a' => 'a', 'c' => 'c'}
          assert_equal 'c', item.c
          assert_nil item.a
        end
        
        should "not allow to set with mass assignment using the constructor" do
          item = ProtectedItem.new(:a => 'a', :c => 'c')
          assert_equal 'c', item.c
          assert_nil item.a
        end
          
        should "allow to set with mass assignment using update_attributes" do
          item = ProtectedItem.new
          item.update_attributes(:a => 'a', :c => 'c')
          item.reload
          assert_equal 'c', item.c
          assert_equal 'a', item.a
        end
          
        should "not allow to set with mass assignment using set_attributes" do
          item = ProtectedItem.new
          item.set_attributes(:a => 'a', :c => 'c')
          assert_equal 'c', item.c
          assert_nil item.a
        end
      end
      
      context "attr_accessible" do
        setup do
          ProtectedItem.instance_eval do
            @_protected_attributes ||= []
            attr_accessible :c
          end
        end
        
        should "not allow to set with mass assignment using attributes=" do
          item = ProtectedItem.new
          item.attributes = {:a => 'a', :c => 'c'}
          assert_equal 'c', item.c
          assert_nil item.a
        end
        
        should "not allow to set with mass assignment using the constructor" do
          item = ProtectedItem.new(:a => 'a', :c => 'c')
          assert_equal 'c', item.c
          assert_nil item.a
        end
          
        should "allow to set with mass assignment using update_attributes" do
          item = ProtectedItem.new
          item.update_attributes(:a => 'a', :c => 'c')
          item.reload
          assert_equal 'c', item.c
          assert_equal 'a', item.a
        end
          
        should "not allow to set with mass assignment using set_attributes" do
          item = ProtectedItem.new
          item.set_attributes(:a => 'a', :c => 'c')
          assert_equal 'c', item.c
          assert_nil item.a
        end
      end
      
    end
    
    context "validation and errors" do
    
      should "get errors" do
        @item.send(:add_error, 'foo', 'bar')
        assert_equal [['foo', 'bar']], @item.errors
      end
    
      should "valid_if_errors" do
        @item.stubs(:errors).returns([true])
        assert !@item.valid?
      end
    
      should "valid_if_no_errors" do
        @item.stubs(:errors).returns([])
        assert @item.valid?
      end
    
      should "clear_errors" do
        @item.instance_variable_set("@errors", [true])
        assert !@item.errors.blank?
        @item.send(:clear_errors)
        assert @item.errors.blank?
      end
    
      should "valid_calls_validate" do
        @item.expects(:validate)
        @item.valid?
      end
    
      should "clears errors on a successful save" do
        @item.expects(:valid?).returns(true)
        @item.expects(:active_sdb_save).returns(true)
        @item.expects(:clear_errors).returns(true)
    
        assert @item.save
      end
    
      should "clear errors when valid? is true" do
        @item.instance_variable_set("@errors", [:am, 'foo'])
        assert @item.valid?
        assert_equal [], @item.instance_variable_get("@errors")
      end
    
      should "fail the save when there's validation errors" do
        @item.instance_variable_set("@errors", [:am, 'foo'])
        @item.stubs(:clear_errors)
        @item.expects(:active_sdb_save).never
        assert !@item.save
      end
    
      should "more_attributes_than_allowed" do
        @item[:foo] = 'bar'
        assert !@item.valid?, @item.attributes.inspect
        assert_equal [['foo', 'is unknown and should not be set']], @item.errors
      end
    
      should "more_attributes_than_allowed_does_not_check_id" do
        @item[:id] = '90834980324kjndfaslkjadsfp89'
        assert @item.valid?, @item.errors.inspect
      end
    
      should "require presence" do
        daddy = ItemDaddy.new
        daddy.name = nil
        assert !daddy.valid?
    
        daddy.name = 'foo'
        assert daddy.valid?
      end
    
      should "require inclusion" do
        @item.foo_attribute = 'd'
        assert !@item.valid?
    
        @item.foo_attribute = 'c'
        assert @item.valid?
      end
    
      should "require inclusion and allow_blank" do
        Item.instance_eval do
          require_inclusion_of :foo_attribute, ['a', 'b', 'c'], :allow_blank => true
        end
    
        item = Item.new(:bar_attribute_array => ['goog'], :foo_attribute => nil)
        assert item.valid?, item.errors.inspect
    
        Item.instance_eval do
          require_inclusion_of :foo_attribute, ['a', 'b', 'c'], :allow_blank => false
        end
    
        assert !item.valid?, item.errors.inspect
      end
    
      should "require inclusion should work with array attribute" do
        @item.bar_attribute_array = ['foobar']
        assert !@item.valid?
    
        @item.bar_attribute_array = ['goog']
        assert @item.valid?
      end
      
      should "save_without_validations" do
        item = Item.new(:foo_attribute => nil)
        assert !item.valid?
        assert !item.save
        assert item.save(false)
      end
      
      context "format validation" do
        setup do
          Item.instance_eval do
            simpledb_string :format_attribute
            require_format_of :format_attribute, /a/, :allow_blank => true
          end
          
          @item = Item.new(:format_attribute => nil, :foo_attribute => 'a')
        end
        
        should "check format" do
          @item.format_attribute = 'b'
          assert !@item.valid?
          
          @item.format_attribute = 'c'
          assert !@item.valid?
          
          @item.format_attribute = 'a'
          assert @item.valid?, @item.errors.inspect
          
          @item.format_attribute = 'abc'
          assert @item.valid?
        end
        
        should "allow nil" do
          @item.format_attribute = 'b'
          assert !@item.valid?
          
          @item.format_attribute = nil
          assert @item.valid?, @item.errors.inspect
        end

      end
    end
    
    context "callbacks" do
    
      should "not call callbacks if none are defined" do      
        @item.stubs(:active_sdb_save).returns(true)
        @item.stubs(:respond_to?).returns(false)
    
        @item.expects(:before_save).never
        @item.expects(:after_save).never
        assert @item.save
      end
    
      should "call callbacks if none are defined" do
        @item.stubs(:active_sdb_save).returns(true)
    
        def @item.before_save
        end
    
        def @item.after_save
        end
    
        @item.expects(:before_save)
        @item.expects(:after_save)
        assert @item.save
      end
    
      should "call after_create and before_create callbacks if we have a new record" do
        @item.stubs(:new_record?).returns(true)
        @item.stubs(:active_sdb_save).returns(true)
    
        def @item.before_create
        end
    
        def @item.after_create
        end
    
        @item.expects(:before_create)
        @item.expects(:after_create)
        assert @item.save
      end
    
      should "not call after_create and before_create callbacks if we have an existing record" do
        @item.stubs(:new_record?).returns(false)
        @item.stubs(:active_sdb_save).returns(true)
    
        def @item.before_create
        end
    
        def @item.after_create
        end
    
        @item.expects(:before_create).never
        @item.expects(:after_create).never
        assert @item.save
      end
    
      should "call before_validation before the validation if defined" do
        def @item.before_validation
        end
    
        @item.expects(:before_validation)
        assert @item.valid?
      end
    
      should "not call before_validation if it is not defined" do
        @item.expects(:respond_to?).with(:before_validation).returns(false)
    
        @item.expects(:before_validation).never
        assert @item.valid?
      end
      
      should "before_delete_callback_not_called_if_no_before_delete_defined" do
        @item.id = '5'
        assert !@item.respond_to?(:before_delete)
        assert_nothing_raised do
          @item.delete
        end
      end
    
      should "before_delete_callback" do
        item_with_callback = Item.create(:foo_attribute => '123', :bar_attribute_array => ['a', 'b'], :id => 5)
        def item_with_callback.before_delete
          'foo'
        end
        item_with_callback.expects(:before_delete)
    
        item_with_callback.delete
      end
    
      should "after_delete_callback_not_called_if_no_before_delete_defined" do
        @item.id = '5'
        assert !@item.respond_to?(:after_delete)
        assert_nothing_raised do
          @item.delete
        end
      end
    
      should "after_delete_callback" do
        item_with_callback = Item.create(:foo_attribute => '123', :bar_attribute_array => ['a', 'b'], :id => 5)
        def item_with_callback.after_delete
          'foo'
        end
        item_with_callback.expects(:after_delete)
    
        item_with_callback.delete
      end
      
    end
    
    context "timestamps" do
    
      should "timestamps" do
        item = Item.new(:foo_attribute => 'a', :bar_attribute_array => ['goog'])
        assert_nil item.updated_at
        assert_nil item.created_at
    
        time = Time.now
        Time.stubs(:now).returns(time)
    
        assert item.save, item.errors.inspect
        assert_equal time.utc, item.updated_at
        assert_equal time.utc, item.created_at
      end
    
      should "timestamps_when_saving_without_validations" do
        item = Item.new(:foo_attribute => 'a', :bar_attribute_array => ['goog'])
        assert_nil item.updated_at
        assert_nil item.created_at
    
        time = Time.now
        Time.stubs(:now).returns(time)
    
        assert item.save(false)
        assert_equal time.utc, item.updated_at
        assert_equal time.utc, item.created_at
      end
    
      should "timestamps_when_existing_record" do
        item = Item.new(:foo_attribute => 'a', :bar_attribute_array => ['goog'])
        item.stubs(:new_record?).returns(false)
        assert_nil item.updated_at
        assert_nil item.created_at
    
        time = Time.now
        Time.stubs(:now).returns(time)
    
        assert item.save, item.errors.inspect
        assert_equal time.utc, item.updated_at
        assert_nil item.created_at
      end
    
      should "timestamps_when_validation_fails" do
        item = Item.new(:foo_attribute => 'a', :bar_attribute_array => ['goog'])
        item.expects(:valid?).returns(false)
        assert_nil item.updated_at
        assert_nil item.created_at    
    
        assert !item.save
        assert_nil item.updated_at
        assert_nil item.created_at
      end
    
      should "timestamp_saves_representation_as_integer" do
        @item.updated_at = Time.local(2004, 1, 12, 9, 7, 59)
        assert_equal ['20040112090759'], @item['updated_at']
      end
    
      should "timestamp_loads_from_representation_as_integer" do
        @item['updated_at'] = '20040112090759'
        assert_equal Time.local(2004, 1, 12, 10, 7, 59).utc, @item.updated_at
      end
    end
    
    context "integer attributes" do
    
      should "save representation padded" do
        @item.integer_field = 91
        assert_equal ['0000000000000091'], @item['integer_field']
      end
    
      should "load representation padded" do
        @item['integer_field'] = '0000000000000091'
        assert_equal 91, @item.integer_field
      end
    end
    
    context "find helper" do
    
      should "all" do
        Item.expects(:find).with(:all, instance_of(Hash))
        Item.all
      end
    
      should "all_with_options" do
        Item.expects(:find).with do |arg, options|
          arg == :all && options[:auto_load] == true
        end
        Item.all(:auto_load => true)
      end
    
      should "first" do
        Item.expects(:find).with(:first, instance_of(Hash))
        Item.first
      end
    
      should "first_with_options" do
        Item.expects(:find).with do |arg, options|
          arg == :first && options[:auto_load] == true
        end
        Item.first(:auto_load => true)
      end
    end
    
    context "when finding an object" do
      should "should raise RecordNotFound when the object wasn't found" do
        assert_raise(SimplyStored::RecordNotFound) do
          Item.find("bla")
        end
      end
    
      should "should retry x-times before raising RecordNotFound" do
        item = create_item
        seq = sequence("find")
        Item.expects(:find_from_ids).with([item.id], {:auto_load => true}).raises(RightAws::ActiveSdb::ActiveSdbError, "Couldn't find Item with ID").in_sequence(seq)
        Item.expects(:find_from_ids).with([item.id], {:auto_load => true}).returns([item]).in_sequence(seq)
        assert_nothing_raised do
          assert Item.find(item.id)
        end
      end
    
      should "should sleep more and more on each subsequent retry" do
        item = create_item
        seq = sequence("find")
        Item.expects(:find_from_ids).with([item.id],{:auto_load => true}).raises(RightAws::ActiveSdb::ActiveSdbError, "Couldn't find Item with ID").in_sequence(seq)
        Item.expects(:find_from_ids).with([item.id],{:auto_load => true}).raises(RightAws::ActiveSdb::ActiveSdbError, "Couldn't find Item with ID").in_sequence(seq)
        Item.expects(:find_from_ids).with([item.id],{:auto_load => true}).raises(RightAws::ActiveSdb::ActiveSdbError, "Couldn't find Item with ID").in_sequence(seq)
      
        sleepy = sequence("sleep")
        Item.expects(:sleep).with(0.5).in_sequence(sleepy)
        Item.expects(:sleep).with(1.0).in_sequence(sleepy)
        assert_raise(SimplyStored::RecordNotFound) do
          Item.find(item.id)
        end
      end
      
      should "retry on system error" do
        item = create_item
        seq = sequence("find")
        item.stubs(:sleep)
        Item.expects(:find_from_ids).with([item.id], {:auto_load => true}).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(seq)
        Item.expects(:find_from_ids).with([item.id], {:auto_load => true}).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(seq)
        Item.expects(:find_from_ids).with([item.id], {:auto_load => true}).returns([item]).in_sequence(seq)
        assert_nothing_raised do
          assert Item.find(item.id)
        end
      end
      
      should "eventually raise an error on system error" do
        item = create_item
        item.stubs(:sleep)
        Item.expects(:find_from_ids).with([item.id], {:auto_load => true}).raises(Rightscale::AwsError, "RequestThrottled").times(3)
        assert_raise(SimplyStored::Error) do
          Item.find(item.id)
        end
      end
      
      should "not retry on client error" do
        item = create_item
        Item.expects(:find_from_ids).with([item.id], {:auto_load => true}).raises(Rightscale::AwsError, "NoSuchDomain")
        assert_raise(SimplyStored::Error) do
          Item.find(item.id)
        end
      end
    
      should "should auto load attributes by default" do
        item = create_item
        item = Item.find(item.id)
        assert item.attributes.size > 1
      end
    end
    
    context "when saving an instance" do
      context "when saving fails due to errors" do
        should "retry save when a system error was raised by simpledb" do
          item = create_item
          sleepy = sequence("sleep")
          item.expects(:sleep).with(0.5).in_sequence(sleepy)
          item.expects(:sleep).with(1.0).in_sequence(sleepy)
          
          raiser = sequence("exception")
          item.expects(:active_sdb_save).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(raiser)
          item.expects(:active_sdb_save).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(raiser)
          item.expects(:active_sdb_save).returns(true).in_sequence(raiser)
          
          item.save
        end
        
        should "not retry when error was a client error" do
          item = create_item
          item.expects(:sleep).never
          item.expects(:active_sdb_save).raises(Rightscale::AwsError, "Ron Telesky")
          assert_raise(SimplyStored::Error) {item.save}
        end
        
        should "raise an error when the world has gone bad" do
          item = create_item
          item.expects(:active_sdb_save).times(3).raises(Rightscale::AwsError, "RequestThrottled")
          assert_raise(SimplyStored::Error) {item.save}
        end
      end
    end
    
    context "when deleting an instance" do
      should "actually delete the instance" do
        @item.save
        @item.delete
        @item.reload
        assert @item.attributes.empty?
      end
      
      should "retry on system error" do
        item = create_item
        sleepy = sequence("sleep")
        item.expects(:sleep).with(0.5).in_sequence(sleepy)
        item.expects(:sleep).with(1.0).in_sequence(sleepy)
        
        raiser = sequence("exception")
        item.expects(:active_sdb_delete).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(raiser)
        item.expects(:active_sdb_delete).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(raiser)
        item.expects(:active_sdb_delete).returns(true).in_sequence(raiser)
        
        item.delete
      end
      
      should "not retry on client error" do
        item = create_item
        item.expects(:sleep).never
        
        item.expects(:active_sdb_delete).raises(Rightscale::AwsError, "NoSuchDomain")
        
        assert_raise(SimplyStored::Error) do
          item.delete
        end
      end
      
      should "eventually raise an error" do
        item = create_item
        item.stubs(:sleep)
        
        item.expects(:active_sdb_delete).raises(Rightscale::AwsError, "NoSuchDomain")
        
        assert_raise(SimplyStored::Error) do
          item.delete
        end
      end
      
    end
    
    context "reload" do
      should "return itself" do
        item = create_item
        assert item.reload.is_a?(Item)
        assert_equal item, item.reload
      end
    end
    
    context "ActiveRecord compatability" do
      should "have a to_param helper" do
        item = create_item
        item.id = 9912
        assert item.save
        assert_equal "9912", item.id
        assert_equal "9912", item.to_param
      end
    end
    
    context "when updating attributes" do
      setup do
        @item = create_item
      end
      
      should "use save_attributes" do
        @item.expects(:active_sdb_save_attributes).with('foo_attribute' => 'b')
        
        @item.update_attributes('foo_attribute' => 'b')
      end
      
      should "nil a nil attribute" do
        @item.update_attributes('foo_attribute' => 'hi')
        assert_equal 'hi', @item.reload.foo_attribute
        
        @item.update_attributes('foo_attribute' => nil)
        assert_nil @item.reload.foo_attribute
      end
      
      should "nil an empty string attribute" do
        @item.update_attributes('foo_attribute' => 'hi')
        assert_equal 'hi', @item.reload.foo_attribute
        
        @item.update_attributes('foo_attribute' => '')
        assert_nil @item.reload.foo_attribute
      end
      
      should "retry on system error" do
        sleepy = sequence("sleep")
        @item.expects(:sleep).with(0.5).in_sequence(sleepy)
        @item.expects(:sleep).with(1.0).in_sequence(sleepy)
        
        raiser = sequence("exception")
        @item.expects(:active_sdb_save_attributes).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(raiser)
        @item.expects(:active_sdb_save_attributes).raises(Rightscale::AwsError, "RequestThrottled").in_sequence(raiser)
        @item.expects(:active_sdb_save_attributes).returns(true).in_sequence(raiser)
        
        @item.update_attributes(:foo_attribute => 'a')
      end
      
      should "not retry on client error" do
        @item.expects(:sleep).never
        
        @item.expects(:active_sdb_save_attributes).raises(Rightscale::AwsError, "NoSuchDomain")
        
        assert_raise(SimplyStored::Error) do
          @item.update_attributes(:foo_attribute => 'a')
        end
      end
      
      should "eventually raise an error on system error" do
        item = create_item
        item.stubs(:sleep)
        
        item.expects(:active_sdb_save_attributes).raises(Rightscale::AwsError, "RequestThrottled").times(3)
        
        assert_raise(SimplyStored::Error) do
          item.update_attributes(:foo_attribute => 'a')
        end
      end
      
    end
    
    context "namespaced classes" do
      
      setup do
        ItemDaddy.instance_eval do
          belongs_to 'namespace__foo'
        end
        @foo = Namespace::Foo.new
        assert @foo.save
      end
      
      should "be able to adress them in belongs_to" do
        daddy = ItemDaddy.new(:name => 'abc')
        daddy.namespace__foo = @foo
        assert daddy.save
      end
      
      should "be able to call a has_many relation" do
        daddy = ItemDaddy.new(:name => 'abc')
        daddy.namespace__foo = @foo
        assert daddy.save
        
        assert_equal daddy.id, ItemDaddy.find_by_namespace__foo_id(@foo.id).id
        assert_equal [daddy].map(&:id), @foo.item_daddys.map(&:id)
      end
      
      should "need special prefix inside namespace" do
        bar = Namespace::Bar.new
        assert bar.save
        @foo.namespace__bar = bar
        assert @foo.save
      end
    end
    
    context "attributes longer than 1024 bytes" do
      setup do
        Item.instance_eval do
          simpledb_string :very_long
        end
        @item = create_item
        @item.very_long = '*' * 1600
        assert_equal 1600, @item.very_long.size
      end
      
      should "add partitioned attributes to the class metadata"
      
      should "not raise an error" do
        assert_nothing_raised do
          @item.save
        end
      end
      
      should "split up the string into numbered attributes by 1024 bytes" do
        @item.save
        assert_equal 1024, @item["very_long_0"].first.size
        assert_equal 576, @item["very_long_1"].first.size
      end
      
      should "store all characters and re-retrieve them on load" do
        @item.save
        @item.reload
        assert_equal 1600, @item.very_long.size
      end

      should "survive several reloads" do
        5.times do
          @item.save
          @item.reload
        end
        assert_equal 1600, @item.very_long.size
        assert_equal 1600, @item["very_long"].first.size
      end
      
      should "unset the original attribute after saving" do
        @item.save
        assert_equal nil, @item["very_long"]
      end
      
      should "still make the attribute available through its accessor" do
        @item.save
        assert_not_nil @item.very_long
      end
    end
    
    context "with attachments" do
      should "add a class method to specify an attachment" do
        assert SimplyStored::Simple.respond_to?(:has_s3_attachment)
      end
      
      should 'store the options in a class accessor' do
        assert LogItem.respond_to?(:_s3_options)
        assert_not_nil LogItem._s3_options
      end
      
      should "include an accessor for the _attachments" do
        assert LogItem.public_instance_methods.grep(/_s3_attachments/)
      end
      
      should "add accessors to the including class" do
        @log_item = LogItem.new
        assert @log_item.respond_to?(:log_data)
        assert @log_item.respond_to?(:log_data=)
      end
      
      should "return the assigned value with the accessor" do
        @log_item = LogItem.new
        @log_item.log_data = "Yay! It logged!"
        assert_equal "Yay! It logged!", @log_item.log_data
      end
      
      should "mark the attachment as changed when assigned a new value" do
        @log_item = LogItem.new
        @log_item.log_data = "Yay! It logged!"
        assert @log_item._s3_attachments[:log_data][:dirty]
      end
      
      should "not include the assigned value to the simpledb attributes" do
        @log_item = LogItem.new
        @log_item.log_data = "Yay! It logged!"
        assert_nil @log_item.attributes[:log_data]
      end
      
      should "raise an error when no bucket was specified" do
        assert_raise(ArgumentError, "No bucket name specified") do
          LogItem.class_eval do
            has_s3_attachment :bla
          end
        end
      end
      
      context "with s3 interaction" do
        setup do
          LogItem.instance_variable_set(:@_s3_connection, nil)
          LogItem._s3_options[:log_data][:ca_file] = nil
          
          bucket = stub(:bckt) do
            stubs(:put).returns(true)
            stubs(:get).returns(true)
          end
          
          @bucket = bucket
          
          @s3 = stub(:s3) do
            stubs(:bucket).returns(bucket)
          end
          
          RightAws::S3.stubs(:new).returns @s3
          @log_item = LogItem.new
        end

        context "when saving the attachment" do
          should "fetch the collection" do
            @log_item.log_data = "Yay! It logged!"
            RightAws::S3.expects(:new).with('abcdef', 'secret!', :multi_thread => true, :ca_file => nil, :logger => nil).returns(@s3)
            @log_item.save
          end
        
          should "upload the file" do
            @log_item.log_data = "Yay! It logged!"
            @bucket.expects(:put).with(anything, "Yay! It logged!", {}, anything)
            @log_item.save
          end
                  
          should "use the specified bucket" do
            @log_item.log_data = "Yay! It logged!"
            LogItem._s3_options[:log_data][:bucket] = 'mybucket'
            @s3.expects(:bucket).with('mybucket').returns(@bucket)
            @log_item.save
          end
          
          should "create the bucket if it doesn't exist" do
            @log_item.log_data = "Yay! log me"
            LogItem._s3_options[:log_data][:bucket] = 'mybucket'
            
            @s3.expects(:bucket).with('mybucket').returns(nil)
            @s3.expects(:bucket).with('mybucket', true, 'private', :location => nil).returns(@bucket)
            @log_item.save
          end
          
          should "accept :us location option but not set it in RightAWS::S3" do
            @log_item.log_data = "Yay! log me"
            LogItem._s3_options[:log_data][:bucket] = 'mybucket'
            LogItem._s3_options[:log_data][:location] = :us

            @s3.expects(:bucket).with('mybucket').returns(nil)
            @s3.expects(:bucket).with('mybucket', true, 'private', :location => nil).returns(@bucket)
            @log_item.save
          end
          
          should "raise an error if the bucket is not ours" do
            @log_item.log_data = "Yay! log me too"
            LogItem._s3_options[:log_data][:bucket] = 'mybucket'
            
            @s3.expects(:bucket).with('mybucket').returns(nil)
            @s3.expects(:bucket).with('mybucket', true, 'private', :location => nil).raises(RightAws::AwsError, 'BucketAlreadyExists: The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again')
            
            assert_raise(ArgumentError) do
              @log_item.save
            end
          end
        
          should "not upload the attachment when it hasn't been changed" do
            @bucket.expects(:put).never
            @log_item.save
          end
        
          should "set the permissions to private by default" do
            class PrivateLogItem < SimplyStored::Simple
              has_s3_attachment :log_data, :bucket => 'mybucket'
            end
            PrivateLogItem.create_domain
            
            @bucket.expects(:put).with(anything, anything, {}, 'private')
            @log_item = PrivateLogItem.new
            
            @log_item.log_data = 'Yay!'
            @log_item.save
          end
        
          should "set the permissions to whatever's specified in the options for the attachment" do
            @log_item.save
            old_perms = LogItem._s3_options[:log_data][:permissions]
            LogItem._s3_options[:log_data][:permissions] = 'public-read'
            @bucket.expects(:put).with(anything, anything, {}, 'public-read')
            @log_item.log_data = 'Yay!'
            @log_item.save
            LogItem._s3_options[:log_data][:permissions] = old_perms
          end
        
          should "use the full class name and the id as key" do
            @log_item.save
            @bucket.expects(:put).with("log_items/log_data/#{@log_item.id}", 'Yay!', {}, anything)
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
            @log_item._s3_options[:log_data][:bucket] = 'bucket-for-monsieur'
            @log_item._s3_options[:log_data][:location] = :us
            @log_item._s3_options[:log_data][:permissions] = 'private'
            @log_item.save
            assert @log_item.log_data_url.gsub("%2F", '/').include?("https://bucket-for-monsieur.s3.amazonaws.com:443/#{@log_item.s3_attachment_key(:log_data)}")
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
            @bucket.expects(:get).with("log_items/log_data/#{@log_item.id}").returns("Yay!")
            assert_equal "Yay!", @log_item.log_data
          end
        
          should "not mark the the attachment as dirty" do
            @log_item.instance_variable_set(:@_s3_attachments, {})
            @bucket.expects(:get).with("log_items/log_data/#{@log_item.id}").returns("Yay!")
            @log_item.log_data
            assert !@log_item._s3_attachments[:log_data][:dirty]
          end
          
          should "not try to fetch the attachment if the value is already set" do
            @log_item.log_data = "Yay!"
            @bucket.expects(:get).never
            assert_equal "Yay!", @log_item.log_data
          end
        end
        
        context "when deleting" do
          setup do
            LogItem._s3_options[:log_data][:after_delete] = :nothing
            @log_item.log_data = 'Yatzzee'
            @log_item.save
          end

          should "do nothing to S3" do
            @bucket.expects(:key).never
            @log_item.delete
          end

          should "also delete on S3 if configured so" do
            LogItem._s3_options[:log_data][:after_delete] = :delete
            s3_key = mock(:delete => true)
            @bucket.expects(:key).with(@log_item.s3_attachment_key('log_data'), true).returns(s3_key)
            @log_item.delete
          end

        end
        
      end
    end
  end
  
  def create_item
    i = Item.new(:foo_attribute => 'a', :bar_attribute_array => ['goog'])
    assert i.save
    i
  end
end