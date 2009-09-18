# Gracefully taken from CouchPotato after it has been removed for good.
module SimplyStored
  module Couch
    module BelongsTo
      
      def belongs_to(name)
        view "association_#{self.name.downcase}_belongs_to_#{name}",
             :map => "function(doc) { if (doc['#{name.to_s}_id'] != null) { log(doc); emit(doc.#{name.to_s}_id, null) }}",
             :type => "custom",
             :include_docs => true
        property name, :class => SimplyStored::Couch::BelongsTo::Property
      end

      class Property #:nodoc:
        attr_accessor :name
      
        def initialize(owner_clazz, name, options = {})
          self.name = name
          item_class_name = self.item_class_name
          owner_clazz.class_eval do
            attr_reader "#{name}_id"
            attr_accessor "#{name}_id_was"
            
            define_method name do
              return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")
              instance_variable_set("@#{name}", send("#{name}_id") ? Object.const_get(item_class_name).find(send("#{name}_id")) : nil)
            end
          
            define_method "#{name}=" do |value|
              klass = self.class.get_class_from_name(name)
              raise ArgumentError, "expected #{klass} got #{value.class}" unless value.is_a?(klass)
              
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
              !self.instance_variable_get("@#{name}_not_changed") && self.send(name) != self.send("#{name}_was")
            end
          end
        end
      
        def save(object)
        end

        def dirty?(object)
          object.send("#{name}_id_was") != object.send("#{name}_id")
        end
      
        def destroy(object)
        
        end
      
        def build(object, json)
          object.send "#{name}_id=", json["#{name}_id"]
          object.send "#{name}_id_was=", json["#{name}_id"]
        end
      
        def serialize(json, object)
          json["#{name}_id"] = object.send("#{name}_id") if object.send("#{name}_id")
        end
      
        def item_class_name
          @name.to_s.camelize
        end
      
      end
    end
  end
end