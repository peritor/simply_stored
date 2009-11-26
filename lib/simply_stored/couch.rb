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
      
      def create(attributes = {})
        instance = new(attributes)
        instance.save
        instance
      end
      
      def find(*args)
        case what = args.pop
        when :all
          CouchPotato.database.view(all_documents(*args))
        when :first
          CouchPotato.database.view(all_documents(:limit => 1)).first
        else
          with_deleted = what.is_a?(Hash) && what[:with_deleted] == true
          what = args.first if with_deleted
          
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
      
      def count
        CouchPotato.database.view(all_documents(:reduce => true))
      end
      
      def enable_soft_delete(property_name = :deleted_at)
        @_soft_delete_attribute = property_name.to_sym
        property property_name, :type => Time
        _define_hard_delete_methods
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
        unless respond_to?(view_name)
          puts "Warning: Defining view #{self.name}##{view_name} at call time, please add it to the class body. (Called from #{caller[1]})"
          view_keys = keys.length == 1 ? keys.first : keys
          view(view_name, :key => view_keys)
        end
        (class << self; self end).instance_eval do
          define_method(name) do |*key_args|
            if keys.length == 1
              key_args = key_args.first
            end 
            CouchPotato.database.view(send(view_name, :key => key_args, :limit => 1, :include_docs => true)).first
          end
        end
        
        send(name, *args)
      end
      
      def _define_bind_all_by(name, *args)
        keys = name.to_s.gsub(/^find_all_by_/, "").split("_and_")
        view_name = name.to_s.gsub(/^find_all_/, "").to_sym
        unless respond_to?(view_name)
          puts "Warning: Defining view #{self.name}##{view_name} at call time, please add it to the class body. (Called from #{caller[0]})"
          view_keys = keys.length == 1 ? keys.first : keys
          view(view_name, :key => view_keys)
        end
        (class << self; self end).instance_eval do
          define_method(name) do |*key_args|
            if keys.length == 1
              key_args = key_args.first
            end
            CouchPotato.database.view(send(view_name, :key => key_args, :include_docs => true))
          end
        end
        send(name, *args)
      end
      
      def _define_count_by(name, *args)
        keys = name.to_s.gsub(/^count_by_/, "").split("_and_")
        view_name = name.to_s.gsub(/^count_/, "").to_sym
        unless respond_to?(view_name)
          puts "Warning: Defining view #{self.name}##{view_name} at call time, please add it to the class body. (Called from #{caller[0]})"
          view_keys = keys.length == 1 ? keys.first : keys
          view(view_name, :key => view_keys)
        end
        (class << self; self end).instance_eval do
          define_method("#{name}") do |*key_args|
            if keys.length == 1
              key_args = key_args.first
            end
            CouchPotato.database.view(send(view_name, :key => key_args, :reduce => true))
          end
        end
      
        send(name, *args)
      end
      
      def method_missing(name, *args)
        if name.to_s =~ /^find_by/
          _define_find_by(name, *args)
        elsif name.to_s =~ /^find_all_by/
          _define_bind_all_by(name, *args)
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
      
    end
  end
end