require 'validatable'
require 'couch_potato'

require 'active_support'
unless {}.respond_to?(:assert_valid_keys)
  require 'active_support/core_ext'
end

require File.expand_path(File.dirname(__FILE__) + '/../simply_stored')
require 'simply_stored/couch/validations'
require 'simply_stored/couch/properties'
require 'simply_stored/couch/finders'
require 'simply_stored/couch/find_by'
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
      include SimplyStored::Couch::Properties
      include SimplyStored::Couch::BelongsTo
      include SimplyStored::Couch::HasMany
      include SimplyStored::Couch::HasOne
      include SimplyStored::Couch::Finders
      include SimplyStored::Couch::FindBy
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
      
      def auto_conflict_resolution_on_save
        @auto_conflict_resolution_on_save.nil? ? true : @auto_conflict_resolution_on_save
      end
      
      def auto_conflict_resolution_on_save=(val)
        @auto_conflict_resolution_on_save = val
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
    
    def self.delete_all_design_documents(database)
      db = CouchRest.database(database)
      db.info # ensure DB exists
      design_docs = CouchRest.get("#{database}/_all_docs?startkey=%22_design%22&endkey=%22_design0%22")['rows'].map do |row|
        [row['id'], row['value']['rev']]
      end
      design_docs.each do |doc_id, rev|
        db.delete_doc({'_id' => doc_id, '_rev' => rev})
      end
      design_docs.size
    end
    
  end
end
