module SimplyStored
  module SimpleDB
    module Associations
      def self.included(base)
        base.extend(ClassMethods)
      end
    
      module ClassMethods
        def belongs_to(klass_name)
          define_belongs_to_getter(klass_name)
          define_belongs_to_setter(klass_name)
        end
  
        def has_one(klass_name, options = {})
          options = {
            :clear => :nullify, # or :destroy
            :dependent => :nullify # or :destroy
          }.update(options)
    
         define_has_one_getter(klass_name, options)
         define_has_one_setter(klass_name, options)
         define_has_one_dependent_clearing(klass_name, options)
        end
  
        def has_many(klass_name, options = {})
          options = {
            :clear => :nullify, # or :destroy
            :dependent => :nullify # or :destroy
          }.update(options)
    
          define_has_many_getter(klass_name, options)
          define_has_many_setter_add(klass_name, options)
          define_has_many_setter_remove(klass_name, options)
          define_has_many_setter_remove_all(klass_name, options)
          define_has_many_dependent_clearing(klass_name, options)
        end
      
        def define_belongs_to_getter(klass_name)
          define_method klass_name.to_s do
            klass = self.class.get_class_from_name(klass_name)
            cached_version = instance_variable_get("@_cached_belongs_to_#{klass_name}")
            if cached_version.nil? and self["#{klass_name}_id"].present?
              cached_version = klass.find(self.send("#{klass_name}_id"), :auto_load => true)
              instance_variable_set("@_cached_belongs_to_#{klass_name}", cached_version)
            end
            cached_version
          end
        end

        def define_belongs_to_setter(klass_name)
          define_method "#{klass_name}=" do |val|
            klass = self.class.get_class_from_name(klass_name)
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)
            self.send("#{klass_name}_id=", val.id)
            instance_variable_set("@_cached_belongs_to_#{klass_name}", val)
          end
        end

        def define_has_one_getter(klass_name, options)
          define_method klass_name.to_s do
            klass = self.class.get_class_from_name(klass_name)
            cached_version = instance_variable_get("@_cached_has_one_#{klass_name}")
            if cached_version
              return cached_version
            else
              cached_version = klass.send("find_by_#{self.class.foreign_key}".to_sym, self.id, {:auto_load => true})
              instance_variable_set("@_cached_has_one_#{klass_name}", cached_version)
              return cached_version
            end
          end
        end

        def define_has_one_setter(klass_name, options)
          define_method "#{klass_name}=" do |val|
            klass = self.class.get_class_from_name(klass_name)
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)

            # clear old
            old = self.send("#{klass_name}")
            old.send("#{self.class.foreign_key}=", nil) if old && options[:clear] == :nullify
            old.delete if old && options[:clear] == :destroy

            # store new
            val.send("#{self.class.foreign_key}=", self.id)
            instance_variable_set("@_cached_has_one_#{klass_name}", val)
          end
        end

        def define_has_one_dependent_clearing(klass_name, options)
          # add method to list of methods to run when deleted
          @_clear_dependents_after_delete_methods ||= []
          @_clear_dependents_after_delete_methods << "has_one_clear_#{klass_name}_after_destroy"

          # define actual clearing/deleting
          define_method "has_one_clear_#{klass_name}_after_destroy" do
            klass = self.class.get_class_from_name(klass_name)
            dependent = klass.send("find_by_#{self.class.foreign_key}".to_sym, self.id)
            if options[:dependent] == :nullify
              dependent.send("#{self.class.foreign_key}=", nil) if dependent
            elsif options[:dependent] == :destroy
              dependent.delete if dependent
            else
              raise ArgumentError, "unknown dependent method: #{options[:dependent].inspect}"
            end
          end
        end

        def define_has_many_getter(klass_name, options)
          define_method klass_name.to_s do
            klass = self.class.get_class_from_name(klass_name)
            cached_version = instance_variable_get("@_cached_has_many_#{klass_name}")
            if cached_version
              return cached_version
            else
              cached_version = klass.send("find_all_by_#{self.class.foreign_key}".to_sym, self.id, {:auto_load => true})
              instance_variable_set("@_cached_has_many_#{klass_name}", cached_version)
              return cached_version
            end
          end
        end

        def define_has_many_setter_add(klass_name, options)
          define_method "add_#{klass_name.to_s.singularize}" do |val|
            klass = self.class.get_class_from_name(klass_name)
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)
            val.send("#{self.class.foreign_key}=", self.id)
            val.save(false)
            cached_version = instance_variable_get("@_cached_has_many_#{klass_name}") || []
            instance_variable_set("@_cached_has_many_#{klass_name}", cached_version << val)
          end
        end

        def define_has_many_setter_remove(klass_name, options)
          define_method "remove_#{klass_name.to_s.singularize}" do |val|
            klass = self.class.get_class_from_name(klass_name)
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)
            raise ArgumentError, "cannot remove not mine" unless val.send(self.class.foreign_key.to_sym) == self.id
            if options[:clear] == :nullify
              val.send("#{self.class.foreign_key}=", nil) 
              val.save(false)
            elsif options[:clear] == :destroy
              val.delete
            else
              raise "Unknown option for clear: #{option[:clear]}"
            end
            cached_version = instance_variable_get("@_cached_has_many_#{klass_name}") || []
            instance_variable_set("@_cached_has_many_#{klass_name}", cached_version.delete_if{|x| x.id == val.id})
          end
        end

        def define_has_many_setter_remove_all(klass_name, options)
          define_method "remove_all_#{klass_name}" do
            klass = self.class.get_class_from_name(klass_name)

            all = klass.send("find_all_by_#{self.class.foreign_key}".to_sym, self.id)

            all.each do |item|
              self.send("remove_#{klass_name.to_s.singularize}", item)
            end
            instance_variable_set("@_cached_has_many_#{klass_name}", [])
          end
        end

        def define_has_many_dependent_clearing(klass_name, options)
          # add method to list of methods to run when deleted
          @_clear_dependents_after_delete_methods ||= []
          @_clear_dependents_after_delete_methods << "has_many_clear_#{klass_name}_after_destroy"

          # define actual clearing/deleting
          define_method "has_many_clear_#{klass_name}_after_destroy" do
            klass = self.class.get_class_from_name(klass_name)
            dependents = klass.send("find_all_by_#{self.class.foreign_key}".to_sym, self.id)
            if options[:dependent] == :nullify
              dependents.each do |dependent|
                dependent.send("#{self.class.foreign_key}=", nil)
              end
            elsif options[:dependent] == :destroy
              dependents.each do |dependent|
                dependent.delete
              end
            else
              raise ArgumentError, "unknown dependent method: #{options[:dependent].inspect}"
            end
          end
        end
      end
    
      def clear_dependents_after_delete
        clear_methods = self.class.instance_variable_get("@_clear_dependents_after_delete_methods") || []
        clear_methods.uniq.each do |clear_method|
          self.send(clear_method)
        end
      end
    end
  end
end