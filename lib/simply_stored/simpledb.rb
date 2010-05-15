require File.expand_path(File.dirname(__FILE__) + '/../simply_stored')

require 'sdb/right_sdb_interface'
require 'sdb/active_sdb'
require "simply_stored/simpledb/attributes"
require "simply_stored/simpledb/associations"
require "simply_stored/simpledb/validations"

module SimplyStored
  class Simple < RightAws::ActiveSdb::Base
    def self.aws_access_key
      @_aws_access_key
    end
    
    def self.aws_secret_access_key
      @_aws_secret_access_key
    end

    def self.aws_access_key=(aws_access_key)
      @_aws_access_key = aws_access_key
    end
    
    def self.aws_secret_access_key=(aws_secret_access_key)
      @_aws_secret_access_key = aws_secret_access_key
    end
    
    include SimplyStored::SimpleDB::Associations
    include SimplyStored::SimpleDB::Attributes
    include SimplyStored::SimpleDB::Validations
    extend SimplyStored::Storage::ClassMethods
  
    alias :active_sdb_save :save
    alias :active_sdb_delete :delete
    alias :active_sdb_save_attributes :save_attributes
  
    def initialize(attrs={})
      attrs = _remove_protected_attributes(attrs) || {}
      super(attrs)
    end
  
    def save(run_validations = true)
      run_validations ? save_with_validations : save_without_validations
    end
  
    def reload
      super
      restore_partitioned_attributes
      self
    end
  
    def save_with_validations
      new_record = new_record? # save status as it changes during saving
      before_create if new_record && respond_to?(:before_create)
      before_save if respond_to?(:before_save)
      if valid?
        set_timestamps
        partition_string_attributes
        sdb_operation(:save)
        clear_errors
        after_create if new_record && respond_to?(:after_create)
        after_save if respond_to?(:after_save)
        true
      else
        false
      end
    end
  
    def save_without_validations
      new_record = new_record? # save status as it changes during saving
      before_create if new_record && respond_to?(:before_create)
      before_save if respond_to?(:before_save)
      set_timestamps
      sdb_operation(:save)
      clear_errors
      after_create if new_record && respond_to?(:after_create)
      after_save if respond_to?(:after_save)
      true
    end
  
    def delete
      before_delete if respond_to?(:before_delete)
      sdb_operation(:delete)
      after_delete if respond_to?(:after_delete)
      clear_dependents_after_delete
      nil
    end
  
    def valid?
      clear_errors
      before_validation if respond_to?(:before_validation)
      ensure_no_foreign_attributes
      ensure_required_attributes_present
      ensure_inclusions
      ensure_formats
      validate
      errors.empty?
    end
  
    def errors
      @errors ||= []
    end
  
    def self.domain
      unless @domain
        if defined? ActiveSupport::CoreExtensions::String::Inflections
          @domain = name.tableize.gsub('/','__').gsub('::','__')
        else
          @domain = name.downcase.gsub('/','__').gsub('::','__')
        end
      end
      @domain
    end
  
    def self.foreign_key
      self.name.underscore.gsub('/','__').gsub('::','__') + "_id"
    end
  
    def self.find(*args)
      retries = 0
      options = args.last.is_a?(Hash) ? args.pop : {}
      options.update(:auto_load => true)
      args << options
      begin
        super(*args)
      rescue Rightscale::AwsError => e
        if (Rightscale::AwsError.system_error?(e) or e.message.match(/^RequestThrottled/)) and retries < 2
          retries += 1
          sleep retries * 0.5
          retry
        else
          raise Error.new("Couldn't find item with #{args.inspect}: #{e}")
        end
      rescue RightAws::ActiveSdb::ActiveSdbError => e
        if e.message.match(/Couldn't find #{name} with ID/)
          if retries < 2
            retries += 1
            sleep retries * 0.5
            retry
          else
            raise RecordNotFound, e.message
          end
        else
          raise
        end
      end
    end
  
    def self.all(options = {})
      find(:all, options)
    end
  
    def self.first(options = {})
      find(:first, options)
    end
  
    def update_attributes(*args)
      # HACK in order to update attributes to nil
      # thank you ActiveSDB
      if (attrs = args.first).is_a?(Hash)
        attrs.each do |k,v|
          attrs[k] = [nil] if v.blank?
        end
      end
    
      sdb_operation(:save_attributes, *args)
    end
  
    def to_param
      id
    end
  
    # set several attrbiutes at once with a given hash
    # in contrast to ActiveSDB#attributes= it doesn't nil the other attributes
    def set_attributes(attrs)
      attrs = _remove_protected_attributes(attrs)
    
      attrs.each do |k,v|
        self[k] = v
      end
    end
  
  protected

    def self.generate_id
      UUIDTools::UUID.random_create().to_s
    end

    def sdb_operation(operation, *args)
      retries = 0
      begin
        send("active_sdb_#{operation}", *args)
      rescue Rightscale::AwsError => e
        if (Rightscale::AwsError.system_error?(e) or e.message.match(/^RequestThrottled/)) and retries < 2
          retries += 1
          sleep retries * 0.5
          retry
        else
          raise Error.new("Couldn't #{operation} item of type #{self.class.name}#{id.nil? ? "" : " (with id: #{id})"}: #{e} #{e.backtrace.join("\n")}")
        end
      end
    end
  
    def set_timestamps
      self.updated_at = Time.now.utc if self.respond_to?(:updated_at=)
      self.created_at = Time.now.utc if self.respond_to?(:created_at=) && self.new_record?
    end
  
    def self.get_class_from_name(klass_name)
      klass_name.to_s.gsub('__','/').classify.constantize
    end
  end
end
