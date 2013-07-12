require 'couch_potato'
require 'active_support'
unless {}.respond_to?(:assert_valid_keys)
  require 'active_support/core_ext'
end

require File.expand_path(File.dirname(__FILE__) + '/../simply_stored')
require 'simply_stored/couch/validations'
require 'simply_stored/couch/association_property'
require 'simply_stored/couch/properties'
require 'simply_stored/couch/finders'
require 'simply_stored/couch/find_by'
require 'simply_stored/couch/belongs_to'
require 'simply_stored/couch/has_many'
require 'simply_stored/couch/has_and_belongs_to_many'
require 'simply_stored/couch/has_one'
require 'simply_stored/couch/ext/couch_potato'
require 'simply_stored/couch/views'
require 'simply_stored/couch/paginator'

if defined?(I18n)
  I18n.load_path << File.expand_path(File.dirname(__FILE__) + '/couch/locale/en.yml')
end

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
        
        view :all_documents, :key => :created_at
      end
    end
    
    module ClassMethods
      include SimplyStored::ClassMethods::Base
      include SimplyStored::Couch::Validations
      include SimplyStored::Couch::Properties
      include SimplyStored::Couch::BelongsTo
      include SimplyStored::Couch::HasMany
      include SimplyStored::Couch::HasAndBelongsToMany
      include SimplyStored::Couch::HasOne
      include SimplyStored::Couch::Finders
      include SimplyStored::Couch::FindBy
      include SimplyStored::Storage::ClassMethods
      
      @@page_params = {}

      def page_params
        @@page_params
      end

      def page_params= options = {}
        @@page_params = options
      end

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
        view :all_documents_without_deleted, :type => SimplyStored::Couch::Views::DeletedModelViewSpec
      end

      def _define_cache_accessors(name, options)
        define_method "_get_cached_#{name}" do
          instance_variable_get("@#{name}") || {}
        end

        define_method "_set_cached_#{name}" do |value, cache_key|
          cached = send("_get_cached_#{name}")
          cached[cache_key] = value
          instance_variable_set("@#{name}", cached)
        end

        define_method "_cache_key_for" do |opt|
          opt.blank? ? :all : opt.to_s
        end
      end
    end

    def extract_association_options(local_options = nil)
      forced_reload = false
      with_deleted = false
      limit = nil
      descending = false
      if local_options
        local_options.assert_valid_keys(:force_reload, :with_deleted, :limit, :order, :page, :per_page, :eager_load)
        forced_reload = local_options.delete(:force_reload)
        with_deleted = local_options[:with_deleted]
        limit = local_options[:limit]
        descending = (local_options[:order] == :desc) ? true : false
      end
      return [forced_reload, with_deleted, limit, descending]
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

    def self.compact_all_design_documents(database)
      db = CouchRest.database(database)
      db.info # ensure DB exists
      design_docs = CouchRest.get("#{database}/_all_docs?startkey=%22_design%22&endkey=%22_design0%22")['rows'].map do |row|
        [row['id'], row['value']['rev']]
      end
      design_docs.each do |doc_id, rev|
        puts "#{database}/_compact/#{doc_id.gsub("_design/",'')}"
        CouchRest.post("#{database}/_compact/#{doc_id.gsub("_design/",'')}")
      end
      design_docs.size
    end
    
  end
end
