module SimplyStored
  module Couch
    module HasMany
      def has_many(name, options = {})
        property name, options.merge(:class => SimplyStored::Couch::HasMany::Property)
      end

      def define_has_many_getter(name)
        define_method(name) do |*args|
          options = args.first && args.first.is_a?(Hash) && args.first
          if options
            options.assert_valid_keys(:force_reload, :with_deleted, :limit)
            forced_reload = options.delete(:force_reload)
            with_deleted = options[:with_deleted]
            limit = options[:limit]
          else
            forced_reload = false
            with_deleted = false
            limit = nil
          end

          cached_results = cached_results = send("_get_cached_#{name}")
          cache_key = _cache_key_for(options)
          if forced_reload || cached_results[cache_key].nil? 
            cached_results[cache_key] = find_associated(name, self.class, :with_deleted => with_deleted, :limit => limit)
            instance_variable_set("@#{name}", cached_results)
          end
          cached_results[cache_key]
        end
      end
      
      def define_has_many_through_getter(name, through)
        raise ArgumentError, "no such relation: #{self} - #{through}" unless instance_methods.map(&:to_sym).include?(through.to_sym)
        
        define_method(name) do |*args|
          options = args.first && args.first.is_a?(Hash) && args.first
          if options
            options.assert_valid_keys(:force_reload, :with_deleted, :limit)
            forced_reload = options[:force_reload]
            with_deleted = options[:with_deleted]
            limit = options[:limit]
          else
            forced_reload = false
            with_deleted = false
            limit = nil
          end
          
          cached_results = send("_get_cached_#{name}")
          cache_key = _cache_key_for(options)
          
          if forced_reload || cached_results[cache_key].nil?
            
            # there is probably a faster way to query this
            intermediate_objects = find_associated(through, self.class, :with_deleted => with_deleted, :limit => limit)
            
            through_objects = intermediate_objects.map do |intermediate_object|
              intermediate_object.send(name.to_s.singularize.underscore, :with_deleted => with_deleted)
            end.flatten.uniq
            cached_results[cache_key] = through_objects
            instance_variable_set("@#{name}", cached_results)
          end
          cached_results[cache_key]
        end
      end
      
      def define_has_many_setter_add(name)
        define_method("add_#{name.to_s.singularize}") do |value|
          klass = self.class.get_class_from_name(name)
          raise ArgumentError, "expected #{klass} got #{value.class}" unless value.is_a?(klass)
          
          value.send("#{self.class.foreign_key}=", id)
          value.save(false)
          
          cached_results = send("_get_cached_#{name}")[:all]
          send("_set_cached_#{name}", (cached_results || []) << value, :all)
          nil
        end
      end

      def define_has_many_setter_remove(name)
        define_method "remove_#{name.to_s.singularize}" do |value|
          klass = self.class.get_class_from_name(name)
          raise ArgumentError, "expected #{klass} got #{value.class}" unless value.is_a?(klass)
          raise ArgumentError, "cannot remove not mine" unless value.send(self.class.foreign_key.to_sym) == id
          
          if self.class._find_property(name).options[:dependent] == :destroy
            value.destroy
          else
            value.send("#{self.class.foreign_key}=", nil) 
            value.save
          end
          
          cached_results = send("_get_cached_#{name}")[:all]
          send("_set_cached_#{name}", (cached_results || []).delete_if{|item| item.id == value.id}, :all)
          nil
        end
      end
      
      def define_has_many_setter_remove_all(name)
        define_method "remove_all_#{name}" do
          all = send("#{name}", :force_reload => true)
          
          all.collect{|i| i}.each do |item|
            send("remove_#{name.to_s.singularize}", item)
          end
        end
      end
      
      def define_has_many_count(name, through = nil)
        method_name = name.to_s.singularize.underscore + "_count"
        define_method(method_name) do |*args|
          options = args.first && args.first.is_a?(Hash) && args.first
          if options
            options.assert_valid_keys(:force_reload, :with_deleted)
            forced_reload = options[:force_reload]
            with_deleted = options[:with_deleted]
          else
            forced_reload = false
            with_deleted = false
          end

          if forced_reload || instance_variable_get("@#{method_name}").nil?
            instance_variable_set("@#{method_name}", count_associated(through || name, self.class, :with_deleted => with_deleted))
          end
          instance_variable_get("@#{method_name}")
        end
      end
      
      def define_cache_accessors(name)
        define_method "_get_cached_#{name}" do
          instance_variable_get("@#{name}") || {}
        end
        
        define_method "_set_cached_#{name}" do |value, cache_key|
          cached = send("_get_cached_#{name}")
          cached[cache_key] = value
          instance_variable_set("@#{name}", cached)
        end
        
        define_method "_cache_key_for" do |options|
          options.blank? ? :all : options.to_s
        end
      end
      
      class Property
        attr_reader :name, :options
        
        def initialize(owner_clazz, name, options = {})
          options = {
            :dependent => :nullify,
            :through => nil
          }.update(options)
          @name, @options = name, options
          
          options.assert_valid_keys(:dependent, :through)
          
          if options[:through]
            owner_clazz.class_eval do
              define_cache_accessors(name)
              define_has_many_through_getter(name, options[:through])
              define_has_many_count(name, options[:through])
            end
          else
            owner_clazz.class_eval do
              define_cache_accessors(name)
              define_has_many_getter(name)
              define_has_many_setter_add(name)
              define_has_many_setter_remove(name)
              define_has_many_setter_remove_all(name)
              define_has_many_count(name)
            end
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