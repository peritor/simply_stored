require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/couch')

class CouchS3Test < Test::Unit::TestCase
  context "with s3 interaction" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
      CouchLogItem.instance_variable_set(:@_s3_connection, nil)
      CouchLogItem._s3_options[:log_data][:ca_file] = nil
      
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
        RightAws::S3.expects(:new).with('abcdef', 'secret!', :multi_thread => true, :ca_file => nil, :logger => nil).returns(@s3)
        @log_item.save
      end
    
      should "upload the file" do
        @log_item.log_data = "Yay! It logged!"
        @bucket.expects(:put).with(anything, "Yay! It logged!", {}, anything)
        @log_item.save
      end
      
      should "also upload on save!" do
        @log_item.log_data = "Yay! It logged!"
        @bucket.expects(:put).with(anything, "Yay! It logged!", {}, anything)
        @log_item.save!
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
        @s3.expects(:bucket).with('mybucket', true, 'private', :location => nil).returns(@bucket)
        @log_item.save
      end
      
      should "accept :us location option but not set it in RightAWS::S3" do
        @log_item.log_data = "Yay! log me"
        CouchLogItem._s3_options[:log_data][:bucket] = 'mybucket'
        CouchLogItem._s3_options[:log_data][:location] = :us
        
        @s3.expects(:bucket).with('mybucket').returns(nil)
        @s3.expects(:bucket).with('mybucket', true, 'private', :location => nil).returns(@bucket)
        @log_item.save
      end
      
      should "raise an error if the bucket is not ours" do
        @log_item.log_data = "Yay! log me too"
        CouchLogItem._s3_options[:log_data][:bucket] = 'mybucket'
        CouchLogItem._s3_options[:log_data][:location] = :eu
        
        @s3.expects(:bucket).with('mybucket').returns(nil)
        @s3.expects(:bucket).with('mybucket', true, 'private', :location => :eu).raises(RightAws::AwsError, 'BucketAlreadyExists: The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again')
        
        assert_raise(ArgumentError) do
          @log_item.save
        end
      end
      
      should "pass the logger object down to RightAws" do
        logger = mock()
        @log_item.log_data = "Yay! log me"
        CouchLogItem._s3_options[:log_data][:bucket] = 'mybucket'
        CouchLogItem._s3_options[:log_data][:logger] = logger
        
        RightAws::S3.expects(:new).with(anything, anything, {:logger => logger, :ca_file => nil, :multi_thread => true}).returns(@s3)
        @log_item.save
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
        @log_item._s3_options[:log_data][:bucket] = 'bucket-for-monsieur'
        @log_item._s3_options[:log_data][:location] = :us
        @log_item._s3_options[:log_data][:permissions] = 'private'
        @log_item.save
        assert @log_item.log_data_url.include?("https://bucket-for-monsieur.s3.amazonaws.com:443/#{@log_item.s3_attachment_key(:log_data)}"), @log_item.log_data_url
        assert @log_item.log_data_url.include?("Signature=")
        assert @log_item.log_data_url.include?("Expires=")
      end
    
      should "serialize data other than strings to json" do
        @log_item.log_data = ['one log entry', 'and another one']
        @bucket.expects(:put).with(anything, '["one log entry","and another one"]', {}, anything)
        @log_item.save
      end
      
      context "when noting the size of the attachment" do
        should "store on upload" do
          @log_item.log_data = 'abc'
          @bucket.expects(:put)
          assert @log_item.save
          assert_equal 3, @log_item.log_data_size
        end
      
        should "update the size if the attachment gets updated" do
          @log_item.log_data = 'abc'
          @bucket.stubs(:put)
          assert @log_item.save
          assert_equal 3, @log_item.log_data_size
        
          @log_item.log_data = 'example'
          assert @log_item.save
          assert_equal 7, @log_item.log_data_size
        end
        
        should "store the size of json attachments" do
          @log_item.log_data = ['abc']
          @bucket.stubs(:put)
          assert @log_item.save
          assert_equal ['abc'].to_json.size, @log_item.log_data_size
        end
      end
    end
  
    context "when fetching the data" do
      should "create a configured S3 connection" do
        CouchLogItem._s3_options[:log_data][:bucket] = 'mybucket'
        CouchLogItem._s3_options[:log_data][:location] = :eu
        CouchLogItem._s3_options[:log_data][:ca_file] = '/etc/ssl/ca.crt'
        
        RightAws::S3.expects(:new).with('abcdef', 'secret!', :multi_thread => true, :ca_file => '/etc/ssl/ca.crt', :logger => nil).returns(@s3)
        
        @log_item.log_data
      end
      
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
    
    context "when deleting" do
      setup do
        CouchLogItem._s3_options[:log_data][:after_delete] = :nothing
        @log_item.log_data = 'Yatzzee'
        @log_item.save
      end
      
      should "do nothing to S3" do
        @bucket.expects(:key).never
        @log_item.delete
      end
      
      should "also delete on S3 if configured so" do
        CouchLogItem._s3_options[:log_data][:after_delete] = :delete
        s3_key = mock(:delete => true)
        @bucket.expects(:key).with(@log_item.s3_attachment_key('log_data'), true).returns(s3_key)
        @log_item.delete
      end
      
    end
  end
end
