module SimplyStored
  module SimpleDB
    module Associations
      def self.included(base)
        base.extend(ClassMethods)
      end
    
      module ClassMethods
        def belongs_to(name, options = nil)
          options = {
            :class_name => self.formalize_class_name(name),
            :foreign_key => "#{name}_id"
          }.update(options || {})
          define_belongs_to_getter(name, options)
          define_belongs_to_setter(name, options)
        end
  
        def has_one(name, options = {})
          options = {
            :clear => :nullify, # or :destroy
            :dependent => :nullify, # or :destroy
            :class_name => self.formalize_class_name(name),
            :foreign_key => self.foreign_key
          }.update(options)
    
         define_has_one_getter(name, options)
         define_has_one_setter(name, options)
         define_has_one_dependent_clearing(name, options)
        end
  
        def has_many(name, options = {})
          options = {
            :clear => :nullify, # or :destroy
            :dependent => :nullify, # or :destroy
            :class_name => self.formalize_class_name(name.to_s.singularize),
            :foreign_key => self.foreign_key
          }.update(options)
    
          define_has_many_getter(name, options)
          define_has_many_setter_add(name, options)
          define_has_many_setter_remove(name, options)
          define_has_many_setter_remove_all(name, options)
          define_has_many_dependent_clearing(name, options)
        end
      
        def define_belongs_to_getter(name, options)
          foreign_key_column = options[:foreign_key]
          define_method(name.to_s) do
            klass = options[:class_name].constantize
            cached_version = instance_variable_get("@_cached_belongs_to_#{name}")
            if cached_version.nil? and self[foreign_key_column].present?
              cached_version = klass.find(self.send(foreign_key_column), :auto_load => true)
              instance_variable_set("@_cached_belongs_to_#{name}", cached_version)
            end
            cached_version
          end
        end

        def define_belongs_to_setter(name, options)
          foreign_key_column = options[:foreign_key]
          define_method("#{name}=") do |val|
            klass = options[:class_name].constantize
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)
            self.send("#{foreign_key_column}=", val.id)
            instance_variable_set("@_cached_belongs_to_#{name}", val)
          end
        end

        def define_has_one_getter(name, options)
          foreign_key_column = options[:foreign_key]
          define_method(name.to_s) do
            klass = options[:class_name].constantize
            cached_version = instance_variable_get("@_cached_has_one_#{name}")
            if cached_version
              cached_version
            else
              cached_version = klass.send("find_by_#{foreign_key_column}".to_sym, self.id, {:auto_load => true})
              instance_variable_set("@_cached_has_one_#{name}", cached_version)
              cached_version
            end
          end
        end

        def define_has_one_setter(name, options)
          foreign_key_column = options[:foreign_key]
          define_method("#{name}=") do |val|
            klass = options[:class_name].constantize
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)

            # clear old
            old = self.send("#{name}")
            old.send("#{foreign_key_column}=", nil) if old && options[:clear] == :nullify
            old.delete if old && options[:clear] == :destroy

            # store new
            val.send("#{foreign_key_column}=", self.id)
            instance_variable_set("@_cached_has_one_#{name}", val)
          end
        end

        def define_has_one_dependent_clearing(name, options)
          # add method to list of methods to run when deleted
          @_clear_dependents_after_delete_methods ||= []
          @_clear_dependents_after_delete_methods << "has_one_clear_#{name}_after_destroy"

          # define actual clearing/deleting
          foreign_key_column = options[:foreign_key]
          define_method("has_one_clear_#{name}_after_destroy") do
            klass = options[:class_name].constantize
            dependent = klass.send("find_by_#{foreign_key_column}".to_sym, self.id)
            case options[:dependent]
            when :nullify then
              dependent.send("#{foreign_key_column}=", nil) if dependent
            when :destroy then
              dependent.delete if dependent
            else
              raise ArgumentError, "unknown dependent method: #{options[:dependent].inspect}"
            end
          end
        end

        def define_has_many_getter(name, options)
          foreign_key_column = options[:foreign_key]
          define_method(name.to_s) do
            klass = options[:class_name].constantize
            cached_version = instance_variable_get("@_cached_has_many_#{name}")
            if cached_version
              cached_version
            else
              cached_version = klass.send("find_all_by_#{foreign_key_column}".to_sym, self.id, {:auto_load => true})
              instance_variable_set("@_cached_has_many_#{name}", cached_version)
              cached_version
            end
          end
        end

        def define_has_many_setter_add(name, options)
          foreign_key_column = options[:foreign_key]
          define_method("add_#{name.to_s.singularize}") do |val|
            klass = options[:class_name].constantize
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)
            val.send("#{foreign_key_column}=", self.id)
            val.save(false)
            cached_version = instance_variable_get("@_cached_has_many_#{name}") || []
            instance_variable_set("@_cached_has_many_#{name}", cached_version << val)
          end
        end

        def define_has_many_setter_remove(name, options)
          foreign_key_column = options[:foreign_key]
          define_method("remove_#{name.to_s.singularize}") do |val|
            klass = options[:class_name].constantize
            raise ArgumentError, "expected #{klass} got #{val.class}" unless val.is_a?(klass)
            raise ArgumentError, "cannot remove not mine" unless val.send(foreign_key_column) == self.id
            case options[:clear]
            when :nullify then
              val.send("#{foreign_key_column}=", nil) 
              val.save(false)
            when :destroy then
              val.delete
            else
              raise "Unknown option for clear: #{option[:clear]}"
            end
            cached_version = instance_variable_get("@_cached_has_many_#{name}") || []
            instance_variable_set("@_cached_has_many_#{name}", cached_version.delete_if{|x| x.id == val.id})
          end
        end

        def define_has_many_setter_remove_all(name, options)
          foreign_key_column = options[:foreign_key]
          define_method("remove_all_#{name}") do
            klass = options[:class_name].constantize
            all = klass.send("find_all_by_#{foreign_key_column}".to_sym, self.id)
            all.each do |item|
              self.send("remove_#{name.to_s.singularize}", item)
            end
            instance_variable_set("@_cached_has_many_#{name}", [])
          end
        end

        def define_has_many_dependent_clearing(name, options)
          # add method to list of methods to run when deleted
          @_clear_dependents_after_delete_methods ||= []
          @_clear_dependents_after_delete_methods << "has_many_clear_#{name}_after_destroy"

          # define actual clearing/deleting
          foreign_key_column = options[:foreign_key]
          define_method("has_many_clear_#{name}_after_destroy") do
            klass = options[:class_name].constantize
            dependents = klass.send("find_all_by_#{foreign_key_column}".to_sym, self.id)
            case options[:dependent]
            when :nullify then
              dependents.each do |dependent|
                dependent.send("#{foreign_key_column}=", nil)
              end
            when :destroy then
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
