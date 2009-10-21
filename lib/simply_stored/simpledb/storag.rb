module SimplyStore
  module Storage
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        cattr_accessor :_s3_options
      end
    end
    
    def s3_connection
      @_s3_connection ||= RightAws::S3.new(AWS_CONFIG[:aws_access_key_id], AWS_CONFIG[:aws_secret_access_key], :multi_thread => true)
    end
    
    def s3_bucket(name)
      if !@_s3_bucket
        @_s3_bucket = s3_connection.bucket(_s3_options[name][:bucket])
        @_s3_bucket = s3_connection.bucket(_s3_options[name][:bucket], true, 'private') if @_s3_bucket.nil? # create it if it didn't exist, do not do it the first time as the ACL get modified
      end
      @_s3_bucket
    rescue Exception => e
      raise ArgumentError, "Could not access/create S3 bucket '#{name}': #{e} #{e.backtrace.join("\n")}"
    end
    
    def save
      if ret = super
        save_attachments
      end
      ret
    end
    
    def save_attachments
      if @_attachments
        @_attachments.each do |name, attachment|
          if attachment[:dirty]
            value = attachment[:value].is_a?(String) ? attachment[:value] : attachment[:value].to_json
            s3_bucket(name).put(s3_attachment_key(name), value, {}, _s3_options[name][:permissions])
            attachment[:dirty] = false
          end
        end
      end
    end
    
    def s3_attachment_key(name)
      "#{self.class.name.tableize}/#{name}/#{id}"
    end
    
    module ClassMethods
      def has_s3_attachment(name, options = {})
        name = name.to_sym
        raise ArgumentError, "No bucket name specified for attachment #{name}" if options[:bucket].blank?
        options.update(:permissions => 'private', :ssl => true)
        self._s3_options ||= {}
        self._s3_options[name] = options
        
        define_attachment_accessors(name)
        attr_reader :_attachments
      end
      
      def define_attachment_accessors(name)
        define_method(name) do
          unless @_attachments and @_attachments[name]
            @_attachments = {name => {}}
            @_attachments[name][:value] = s3_bucket(name).get(s3_attachment_key(name))
          end
          @_attachments[name][:value]
        end
        
        define_method("#{name}=") do |value|
          @_attachments ||= {}
          @_attachments[name] ||= {}
          @_attachments[name].update(:value => value, :dirty => true)
          value
        end
        
        define_method("#{name}_url") do
          if _s3_options[name][:permissions] == 'private'
            RightAws::S3Generator.new(AWS_CONFIG[:aws_access_key_id], AWS_CONFIG[:aws_secret_access_key], :multi_thread => true).bucket(_s3_options[name][:bucket]).get(s3_attachment_key(name), 5.minutes)
          else
            "http://#{_s3_options[name][:bucket].to_s}.s3.amazonaws.com/#{s3_attachment_key(name)}"
          end
        end
      end
    end
  end
end