module SimplyStored
  module Storage
    module InstanceMethods
      def _s3_options
        self.class._s3_options
      end
      
      def s3_connection(name)
        @_s3_connection ||= RightAws::S3.new(_s3_options[name][:access_key], _s3_options[name][:secret_access_key], :multi_thread => true, :ca_file => _s3_options[name][:ca_file], :logger => _s3_options[name][:logger])
      end
    
      def s3_bucket(name)
        if !@_s3_bucket
          @_s3_bucket = s3_connection(name).bucket(_s3_options[name][:bucket])
          location = (_s3_options[name][:location] == :eu) ? :eu : nil
          @_s3_bucket = s3_connection(name).bucket(_s3_options[name][:bucket], true, _s3_options[name][:permissions], :location => location) if @_s3_bucket.nil?
        end
        @_s3_bucket
      rescue Exception => e
        raise ArgumentError, "Could not access/create S3 bucket '#{name}': #{e} #{e.backtrace.join("\n")}"
      end
    
      def save(validate = true)
        update_attachment_sizes
        if ret = super(validate)
          save_attachments
        end
        ret
      end
      
      def save!(*args)
        update_attachment_sizes
        super
        save_attachments
      end
      
      def delete(*args)
        delete_attachments
        super
      end
      
      def destroy(*args)
        delete_attachments
        super
      end
    
      def save_attachments
        return unless id.present?
        if @_s3_attachments
          @_s3_attachments.each do |name, attachment|
            if attachment[:dirty]
              value = attachment[:value].is_a?(String) ? attachment[:value] : attachment[:value].to_json
              s3_bucket(name).put(s3_attachment_key(name), value, {}, _s3_options[name][:permissions])
              attachment[:dirty] = false
            end
          end
        end
      end
      
      def delete_attachments
        return unless id.present?
        (@_s3_attachments || {}).each do |name, attachment|
          if _s3_options[name][:after_delete] == :delete
            key = s3_bucket(name).key(s3_attachment_key(name), true)
            key.delete
          end
        end
      end
      
      def update_attachment_sizes
        if @_s3_attachments
          @_s3_attachments.each do |name, attachment|
            if attachment[:dirty]
              value = attachment[:value].is_a?(String) ? attachment[:value] : attachment[:value].to_json
              send("#{name}_size=", (value.size rescue nil))
            end
          end
        end
      end
    
      def s3_attachment_key(name)
        "#{self.class.name.tableize}/#{name}/#{id}"
      end
    end
    
    module ClassMethods
      def has_s3_attachment(name, options = {})
        require 'right_aws'
        
        name = name.to_sym
        
        self.class.instance_eval do
          attr_accessor :_s3_options
        end
        
        self.class_eval do
          if respond_to?(:property)
            property "#{name}_size"
          else
            simpledb_integer "#{name}_size"
          end
        end
        
        raise ArgumentError, "No bucket name specified for attachment #{name}" if options[:bucket].blank?
        options = {
          :permissions => 'private', 
          :ssl => true, 
          :location => :us, # use :eu for European buckets
          :ca_file => nil, # point to CA file for SSL certificate verification
          :after_delete => :nothing, # or :delete to delete the item on S3 after it is deleted in the DB,
          :logger => nil # use the default RightAws logger (stdout)
        }.update(options)
        self._s3_options ||= {}
        self._s3_options[name] = options
        
        define_attachment_accessors(name)
        attr_reader :_s3_attachments
        include InstanceMethods
      end
      
      def define_attachment_accessors(name)
        define_method(name) do
          unless @_s3_attachments and @_s3_attachments[name]
            @_s3_attachments = {name => {}}
            @_s3_attachments[name][:value] = s3_bucket(name).get(s3_attachment_key(name))
          end
          @_s3_attachments[name][:value]
        end
        
        define_method("#{name}=") do |value|
          @_s3_attachments ||= {}
          @_s3_attachments[name] ||= {}
          @_s3_attachments[name].update(:value => value, :dirty => true)
          value
        end
        
        define_method("#{name}_url") do
          if _s3_options[name][:permissions] == 'private'
            RightAws::S3Generator.new(_s3_options[name][:access_key], _s3_options[name][:secret_access_key], :multi_thread => true, :ca_file => _s3_options[name][:ca_file]).bucket(_s3_options[name][:bucket]).get(s3_attachment_key(name), 5.minutes)
          else
            if _s3_options[name][:https]
              "https://#{_s3_options[name][:bucket].to_s}.s3.amazonaws.com/#{s3_attachment_key(name)}"
            else
              "http://#{_s3_options[name][:bucket].to_s}.s3.amazonaws.com/#{s3_attachment_key(name)}"
            end
          end
        end
      end
    end
  end
end
