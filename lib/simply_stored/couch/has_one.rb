module SimplyStored
  module Couch
    module HasOne
      def has_one(name, options = {})
        property name, options.merge(:class => SimplyStored::Couch::HasOne::Property)
      end
      
      def define_has_one_setter(name)
        define_method("#{name}=") do |value|
          klass = self.class.get_class_from_name(name)
          raise ArgumentError, "expected #{klass} got #{value.class}" unless value.nil? || value.is_a?(klass)
          old_value = send("#{name}", :force_reload => true)
          if value.nil?
            instance_variable_set("@#{name}", nil)
          else
            instance_variable_set("@#{name}", value)
            value.send("#{self.class.foreign_key}=", id)
            value.save
          end
          
          if old_value
            if self.class._find_property(name).options[:dependent] == :destroy
              old_value.destroy
            else
              old_value.send("#{self.class.foreign_property}=", nil)
              old_value.save
            end
          end
          old_value
        end
      end
      
      def define_has_one_getter(name)
        define_method(name) do |*args|
          options = args.first && args.first.is_a?(Hash) && args.first
          if options
            options.assert_valid_keys(:force_reload, :with_deleted)
            forced_reload = options[:force_reload]
            with_deleted = options[:with_deleted]
          else
            forced_reload = false
            with_deleted = false
          end

          if forced_reload || instance_variable_get("@#{name}").nil?
            instance_variable_set("@#{name}", find_one_associated(name, self.class, :with_deleted => with_deleted))
          end
          instance_variable_get("@#{name}")
        end
      end
      
      class Property
        attr_reader :name, :options
      
        def initialize(owner_clazz, name, options = {})
          options = {:dependent => :nullify}.update(options)
          @name, @options = name, options
          
          options.assert_valid_keys(:dependent)
          
          owner_clazz.class_eval do
            define_has_one_getter(name)
            define_has_one_setter(name)
          end
        end

        def save(object)
        end

        def dirty?(object)
          false
        end

        def destroy(object)
        end

        def build(object, json)
        end

        def serialize(json, object)
        end
        
        def supports_dirty?
          false
        end
        
        def association?
          true
        end
      end
    end
  end
end