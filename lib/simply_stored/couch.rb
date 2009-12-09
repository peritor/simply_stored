require 'couch_potato'

require File.expand_path(File.dirname(__FILE__) + '/../simply_stored')
require 'simply_stored/couch/validations'
require 'simply_stored/couch/belongs_to'
require 'simply_stored/couch/has_many'
require 'simply_stored/couch/has_one'
require 'simply_stored/couch/ext/couch_potato'
require 'simply_stored/couch/views'

module SimplyStored
  module Couch
    def self.included(clazz)
      clazz.class_eval do
        include CouchPotato::Persistence
        include InstanceMethods
        extend ClassMethods
      end
      
      clazz.instance_eval do
        attr_accessor :_accessible_attributes, :_protected_attributes
        alias :simpledb_array :simpledb_string
        alias :simpledb_integer :simpledb_string
        
        view :all_documents, :key => :created_at
      end
    end
    
    module ClassMethods
      include SimplyStored::ClassMethods::Base
      include SimplyStored::Couch::Validations
      include SimplyStored::Couch::BelongsTo
      include SimplyStored::Couch::HasMany
      include SimplyStored::Couch::HasOne
      include SimplyStored::Storage::ClassMethods
      
      def create(attributes = {}, &blk)
        instance = new(attributes, &blk)
        instance.save
        instance
      end

      def create!(attributes = {}, &blk)
        instance = new(attributes, &blk)
        instance.save!
        instance
      end
      
      def find(*args)
        what = args.shift
        options = args.last.is_a?(Hash) ? args.last : {}
        
        options.assert_valid_keys(:with_deleted)
        with_deleted = options.delete(:with_deleted)
        
        case what
        when :all
          if with_deleted || !soft_deleting_enabled?
            CouchPotato.database.view(all_documents(*args))
          else
            CouchPotato.database.view(all_documents_without_deleted(:key => nil))
          end
        when :first
          if with_deleted || !soft_deleting_enabled?
            CouchPotato.database.view(all_documents(:limit => 1)).first
          else
            CouchPotato.database.view(all_documents_without_deleted(:key => nil, :limit => 1)).first
          end
        else          
          raise SimplyStored::Error, "Can't load record without an id" if what.nil?
          document = CouchPotato.database.load_document(what)
          if document.nil? or !document.is_a?(self) or (document.deleted? && !with_deleted)
            raise(SimplyStored::RecordNotFound)
          end
          document
        end
      end
      
      def all
        find(:all)
      end
      
      def first
        find(:first)
      end
      
      def count(options = {})
        options.assert_valid_keys(:with_deleted)
        with_deleted = options[:with_deleted]
        
        if with_deleted || !soft_deleting_enabled?
          CouchPotato.database.view(all_documents(:reduce => true))
        else
          CouchPotato.database.view(all_documents_without_deleted(:reduce => true, :key => nil))
        end
      end
      
      def enable_soft_delete(property_name = :deleted_at)
        @_soft_delete_attribute = property_name.to_sym
        property property_name, :type => Time
        _define_hard_delete_methods
        _define_soft_delete_views
      end
      
      def soft_delete_attribute
        @_soft_delete_attribute
      end
      
      def soft_deleting_enabled?
        !soft_delete_attribute.nil?
      end
      
      def simpledb_string(*names)
        names.each do |name|
          property name
        end
      end
      
      def simpledb_timestamp(*names)
        names.each do |name|
          property name, :type => Time
        end
      end
      
      def require_attributes(*names)
        names.each do |name|
          validates_presence_of name
        end
      end

      def require_inclusion_of(name, valid_set, options = {})
        options.update(:in => valid_set)
        validates_inclusion_of(name, options)
      end
      
      def require_format_of(attr, valid_regex, options = {})
        options.update(:with => valid_regex)
        validates_format_of(attr, options)
      end
      
      def _define_find_by(name, *args)
        keys = name.to_s.gsub(/^find_by_/, "").split("_and_")
        view_name = name.to_s.gsub(/^find_/, "").to_sym
        view_keys = keys.length == 1 ? keys.first : keys
        without_deleted_view_name = "#{view_name}_withoutdeleted"
        without_deleted_view_keys = keys + [:deleted_at]
        
        unless respond_to?(view_name)
          puts "Warning: Defining view #{self.name}##{view_name} with keys #{view_keys.inspect} at call time, please add it to the class body. (Called from #{caller[0]})"
          view(view_name, :key => view_keys)
        end
        
        if !respond_to?(without_deleted_view_name) && soft_deleting_enabled?
          puts "Warning: Defining view #{self.name}##{without_deleted_view_name} with keys #{without_deleted_view_keys.inspect} at call time, please add it to the class body. (Called from #{caller[0]})"
          view(without_deleted_view_name, :key => without_deleted_view_keys)
        end
        
        (class << self; self end).instance_eval do
          define_method(name) do |*key_args|
            options = key_args.last.is_a?(Hash) ? key_args.pop : {}
            options.assert_valid_keys(:with_deleted)
            with_deleted = options.delete(:with_deleted)
            
            raise ArgumentError, "Too many or too few arguments, require #{keys.inspect}" unless keys.size == key_args.size            
            
            if soft_deleting_enabled? && !with_deleted
              key_args = key_args + [nil] # deleted_at
              CouchPotato.database.view(send(without_deleted_view_name, :key => (key_args.size == 1 ? key_args.first : key_args), :limit => 1, :include_docs => true)).first
            else
              CouchPotato.database.view(send(view_name, :key => (key_args.size == 1 ? key_args.first : key_args), :limit => 1, :include_docs => true)).first
            end
          end
        end
        
        send(name, *args)
      end
      
      def _define_find_all_by(name, *args)
        keys = name.to_s.gsub(/^find_all_by_/, "").split("_and_")
        view_name = name.to_s.gsub(/^find_all_/, "").to_sym
        view_keys = keys.length == 1 ? keys.first : keys
        without_deleted_view_name = "#{view_name}_withoutdeleted"
        without_deleted_view_keys = keys + [:deleted_at]
        
        unless respond_to?(view_name)
          puts "Warning: Defining view #{self.name}##{view_name} with keys #{view_keys.inspect} at call time, please add it to the class body. (Called from #{caller[0]})"
          view(view_name, :key => view_keys)
        end
        
        if !respond_to?(without_deleted_view_name) && soft_deleting_enabled?
          puts "Warning: Defining view #{self.name}##{without_deleted_view_name} with keys #{without_deleted_view_keys.inspect} at call time, please add it to the class body. (Called from #{caller[0]})"
          view(without_deleted_view_name, :key => without_deleted_view_keys)
        end
        
        (class << self; self end).instance_eval do
          define_method(name) do |*key_args|
            options = key_args.last.is_a?(Hash) ? key_args.pop : {}
            options.assert_valid_keys(:with_deleted)
            with_deleted = options.delete(:with_deleted)
            
            raise ArgumentError, "Too many or too few arguments, require #{keys.inspect}" unless keys.size == key_args.size            
            
            if soft_deleting_enabled? && !with_deleted
              key_args = key_args + [nil] # deleted_at
              CouchPotato.database.view(send(without_deleted_view_name, :key => (key_args.size == 1 ? key_args.first : key_args), :include_docs => true))
            else
              CouchPotato.database.view(send(view_name, :key => (key_args.size == 1 ? key_args.first : key_args), :include_docs => true))
            end
          end
        end
        send(name, *args)
      end
      
      def _define_count_by(name, *args)
        keys = name.to_s.gsub(/^count_by_/, "").split("_and_")
        view_name = name.to_s.gsub(/^count_/, "").to_sym
        view_keys = keys.length == 1 ? keys.first : keys
        without_deleted_view_name = "#{view_name}_withoutdeleted"
        without_deleted_view_keys = keys + [:deleted_at]
        
        unless respond_to?(view_name)
          puts "Warning: Defining view #{self.name}##{view_name} with keys #{view_keys.inspect} at call time, please add it to the class body. (Called from #{caller[0]})"
          view(view_name, :key => view_keys)
        end
        
        if !respond_to?(without_deleted_view_name) && soft_deleting_enabled?
          puts "Warning: Defining view #{self.name}##{without_deleted_view_name} with keys #{without_deleted_view_keys.inspect} at call time, please add it to the class body. (Called from #{caller[0]})"
          view(without_deleted_view_name, :key => without_deleted_view_keys)
        end
        
        (class << self; self end).instance_eval do
          define_method("#{name}") do |*key_args|
            options = key_args.last.is_a?(Hash) ? key_args.pop : {}
            options.assert_valid_keys(:with_deleted)
            with_deleted = options.delete(:with_deleted)
            
            if soft_deleting_enabled? && !with_deleted
              key_args = key_args + [nil] # deleted_at
              CouchPotato.database.view(send(without_deleted_view_name, :key => (key_args.size == 1 ? key_args.first : key_args), :reduce => true))
            else
              CouchPotato.database.view(send(view_name, :key => (key_args.size == 1 ? key_args.first : key_args), :reduce => true))
            end
            
          end
        end
      
        send(name, *args)
      end
      
      def method_missing(name, *args)
        if name.to_s =~ /^find_by/
          _define_find_by(name, *args)
        elsif name.to_s =~ /^find_all_by/
          _define_find_all_by(name, *args)
        elsif name.to_s =~ /^count_by/
          _define_count_by(name, *args)
        else
          super
        end
      end
      
      def _define_hard_delete_methods
        define_method("destroy!") do
          destroy(true)
        end
        
        define_method("delete!") do
          destroy(true)
        end
      end
      
      def _define_soft_delete_views 
        view :all_documents_without_deleted, :key => soft_delete_attribute
      end
      
    end
  end
end