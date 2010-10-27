# Gracefully taken from CouchPotato after it has been removed for good.
module SimplyStored
  module Couch
    module BelongsTo
      include SimplyStored::Couch::Properties

      def belongs_to(name, options = {})
        check_existing_properties(name, SimplyStored::Couch::BelongsTo::Property)

        map_definition_without_deleted = <<-eos
          function(doc) { 
            if (doc['ruby_class'] == '#{self.to_s}' && doc['#{name.to_s}_id'] != null) {
              if (doc['#{soft_delete_attribute}'] && doc['#{soft_delete_attribute}'] != null){
                // "soft" deleted
              }else{
                emit([doc.#{name.to_s}_id, doc.created_at], 1);
              }
            }
          }
        eos
        
        reduce_definition = "_sum"
        # reduce_definition = <<-eos
        #   function(key, values) {
        #     return sum(values);
        #   }
        # eos
         
        view "association_#{self.name.underscore}_belongs_to_#{name}",
          :map => map_definition_without_deleted,
          :reduce => reduce_definition,
          :type => "custom",
          :include_docs => true
          
        map_definition_with_deleted = <<-eos
          function(doc) { 
            if (doc['ruby_class'] == '#{self.to_s}' && doc['#{name.to_s}_id'] != null) {
              emit([doc.#{name.to_s}_id, doc.created_at], 1);
            }
          }
        eos
         
        view "association_#{self.name.underscore}_belongs_to_#{name}_with_deleted",
          :map => map_definition_with_deleted,
          :reduce => reduce_definition,
          :type => "custom",
          :include_docs => true
            
        properties << SimplyStored::Couch::BelongsTo::Property.new(self, name, options)
      end

      class Property #:nodoc:
        attr_accessor :name, :options
      
        def initialize(owner_clazz, name, options = {})
          @name = name
          @options = {
            :class_name => name.to_s.singularize.camelize
          }.update(options)

          @options.assert_valid_keys(:class_name)

          owner_clazz.class_eval do
            attr_reader "#{name}_id"
            attr_accessor "#{name}_id_was"
            property "#{name}_id"
            
            define_method name do |*args|
              local_options = args.last.is_a?(Hash) ? args.last : {}
              local_options.assert_valid_keys(:force_reload, :with_deleted)
              forced_reload = local_options[:force_reload] || false
              with_deleted = local_options[:with_deleted] || false
              
              return instance_variable_get("@#{name}") unless instance_variable_get("@#{name}").nil? or forced_reload
              instance_variable_set("@#{name}", send("#{name}_id").present? ? Object.const_get(self.class._find_property(name).options[:class_name]).find(send("#{name}_id"), :with_deleted => with_deleted) : nil)
            end
          
            define_method "#{name}=" do |value|
              klass = self.class.get_class_from_name(self.class._find_property(name).options[:class_name])
              raise ArgumentError, "expected #{klass} got #{value.class}" unless value.nil? || value.is_a?(klass)

              instance_variable_set("@#{name}", value)
              if value.nil?
                instance_variable_set("@#{name}_id", nil)
              else
                instance_variable_set("@#{name}_id", value.id)
              end
            end

            define_method "#{name}_id=" do |id|
              remove_instance_variable("@#{name}") if instance_variable_defined?("@#{name}")
              instance_variable_set("@#{name}_id", id)
            end
            
            define_method "#{name}_changed?" do
              self.send("#{name}_id") != self.send("#{name}_id_was")
            end
          end
        end
      
        def dirty?(object)
          object.send("#{name}_id_was") != object.send("#{name}_id")
        end
        
        def reset_dirty_attribute(object)
          object.send("#{name}_id_was=", object.send("#{name}_id"))
        end
        
        def build(object, json)
          object.send "#{name}_id=", json["#{name}_id"]
          object.send "#{name}_id_was=", json["#{name}_id"]
        end
      
        def serialize(json, object)
          json["#{name}_id"] = object.send("#{name}_id") if object.send("#{name}_id")
        end
        alias :value :serialize
            
        def association?
          true
        end
      end
    end
  end
end
