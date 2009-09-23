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
          CouchPotato.database.load_document(what) || raise(SimplyStored::RecordNotFound)
        end
      end
      
      def all
        find(:all)
      end
      
      def first
        find(:first)
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
          keys = name.to_s.gsub(/^find_by_/, "").split("_and_")
          view_name = name.to_s.gsub(/^find_/, "").to_sym
          unless respond_to?(view_name)
            puts "Warning: Defining view #{view_name} at call time, please add it to the class body. (Called from #{caller[0]})"
            view_keys = keys.length == 1 ? keys.first : keys
            view(view_name, :key => view_keys)
          end
          self.class.instance_eval do
            define_method(name) do |*key_args|
              if keys.length == 1
                key_args = key_args.first
              end 
              CouchPotato.database.view(send(view_name, :key => key_args, :limit => 1, :include_docs => true)).first
            end
          end
          
          send(name, *args)
        elsif name.to_s =~ /^find_all_by/
          keys = name.to_s.gsub(/^find_all_by_/, "").split("_and_")
          view_name = name.to_s.gsub(/^find_all_/, "").to_sym
          unless respond_to?(view_name)
            puts "Warning: Defining view #{view_name} at call time, please add it to the class body. (Called from #{caller[0]})"
            view_keys = keys.length == 1 ? keys.first : keys
            view(view_name, :key => view_keys)
          end
          self.class.instance_eval do
            define_method(name) do |*key_args|
              if keys.length == 1
                key_args = key_args.first
              end
              CouchPotato.database.view(send(view_name, :key => key_args, :include_docs => true))
            end
          end

          send(name, *args)
        else
          super
        end
      end
    end
  end
end