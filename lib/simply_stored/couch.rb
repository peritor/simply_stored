require 'simply_stored/couch/validations'
require 'simply_stored/couch/belongs_to'
require 'simply_stored/couch/has_many'
require 'simply_stored/couch/has_one'
require 'simply_stored/couch/ext/couch_potato'

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
          CouchPotato.database.view(all, *args)
        else
          CouchPotato.database.load_document(what)
        end
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
        validates_inclusion_of(name, :in => valid_set)
      end
      
      def require_format_of(attr, valid_regex, options = {})
        validates_format_of(attr, :with => valid_regex)
      end
      
      def method_missing(name, *args)
        if name.to_s =~ /^find_by/
          keys = name.to_s.gsub(/^find_by_/, "").split("_and_")
          view_name = name.to_s.gsub(/^find_/, "").to_sym
          puts "Warning: Defining view #{view_name} at call time, please add it to the class body. (Called from #{caller[0]})"
          view view_name, :key => keys
          self.class.instance_eval do
            define_method(name) do 
              CouchPotato.database.view(send(view_name, :key => args, :limit => 1)).first
            end
          end
          
          send(name, args)
        elsif name.to_s =~ /^find_all_by/
          keys = name.to_s.gsub(/^find_all_by_/, "").split("_and_")
          view_name = name.to_s.gsub(/^find_/, "").to_sym
          puts "Warning: Defining view #{view_name} at call time, please add it to the class body. (Called from #{caller[0]})"
          view view_name, :key => keys
          self.class.instance_eval do
            define_method(name) do 
              CouchPotato.database.view(send(view_name, :key => args))
            end
          end

          send(name, args)
        
        else
          super
        end
      end
    end
  end
end