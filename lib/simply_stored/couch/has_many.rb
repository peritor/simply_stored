module SimplyStored
  module Couch
    module HasMany
      def has_many(name, options = {})
        check_existing_properties(name, SimplyStored::Couch::HasMany::Property)
        properties << SimplyStored::Couch::HasMany::Property.new(self, name, options)
      end

      def define_has_many_getter(name, options)
        define_method(name) do |*args|
          options[:class_name].constantize.page_params = args.first if args.first.is_a? Hash
          local_options = args.first && args.first.is_a?(Hash) && args.first
          forced_reload, with_deleted, limit, descending = extract_association_options(local_options)

          eager_load_params = nil
          args.each do |arg| 
            if arg[:eager_load]
              eager_load_params = args.delete(arg)
              eager_load_params = eager_load_params[:eager_load]
            end
          end

          cached_results = send("_get_cached_#{name}")
          cache_key = _cache_key_for(local_options)

          if forced_reload || cached_results[cache_key].nil? 
            cached_results[cache_key] = find_associated(options[:class_name], self.class, :with_deleted => with_deleted, :limit => limit, :descending => descending, :foreign_key => options[:foreign_key], :eager_load => eager_load_params)
            instance_variable_set("@#{name}", cached_results)
            self.class.set_parent_has_many_association_object(self, cached_results[cache_key])
          end
          cached_results[cache_key]
        end
      end
      
      def define_has_many_through_getter(name, options, through)
        raise ArgumentError, "no such relation: #{self} - #{through}" unless instance_methods.map(&:to_sym).include?(through.to_sym)
        
        define_method(name) do |*args|
          local_options = args.first && args.first.is_a?(Hash) && args.first
          if local_options
            local_options.assert_valid_keys(:force_reload, :with_deleted, :limit)
            forced_reload = local_options[:force_reload]
            with_deleted = local_options[:with_deleted]
            limit = local_options[:limit]
          else
            forced_reload = false
            with_deleted = false
            limit = nil
          end
          
          cached_results = send("_get_cached_#{name}")
          cache_key = _cache_key_for(local_options)
          
          if forced_reload || cached_results[cache_key].nil?
            
            # there is probably a faster way to query this
            intermediate_objects = find_associated(through, self.class, :with_deleted => with_deleted, :limit => limit, :foreign_key => options[:foreign_key])
            
            through_objects = intermediate_objects.map do |intermediate_object|
              intermediate_object.send(name.to_s.singularize.underscore, :with_deleted => with_deleted)
            end.flatten.uniq
            cached_results[cache_key] = through_objects
            instance_variable_set("@#{name}", cached_results)
          end
          cached_results[cache_key]
        end
      end
      
      def define_has_many_setter_add(name, options)
        define_method("add_#{name.to_s.singularize}") do |value|
          if !options[:class_name].blank?
            klass = self.class.get_class_from_name(options[:class_name])
          else
            klass = self.class.get_class_from_name(name)          
          end
          raise ArgumentError, "expected #{klass} got #{value.class}" unless value.is_a?(klass)
          
          if !options[:foreign_key].blank?          
            value.send("#{options[:foreign_key]}=", id)
          else
            value.send("#{self.class.foreign_key}=", id)
          end
          value.save(false)
          
          cached_results = send("_get_cached_#{name}")[:all]
          send("_set_cached_#{name}", (cached_results || []) << value, :all)
          nil
        end
      end

      def define_has_many_setter_remove(name, options)
        define_method "remove_#{name.to_s.singularize}" do |value|
          klass = self.class.get_class_from_name(name)
          raise ArgumentError, "expected #{klass} got #{value.class}" unless value.is_a?(klass)
          raise ArgumentError, "cannot remove not mine" unless value.send(self.class.foreign_key.to_sym) == id

          if options[:dependent] == :destroy
            value.destroy
          elsif options[:dependent] == :ignore
            # skip
          else # nullify
            value.send("#{self.class.foreign_key}=", nil)
            value.save(false)
          end
          
          cached_results = send("_get_cached_#{name}")[:all]
          send("_set_cached_#{name}", (cached_results || []).delete_if{|item| item.id == value.id}, :all)
          nil
        end
      end
      
      def define_has_many_setter_remove_all(name, options)
        define_method "remove_all_#{name}" do
          all = send("#{name}", :force_reload => true)
          
          all.collect{|i| i}.each do |item|
            send("remove_#{name.to_s.singularize}", item)
          end
        end
      end
      
      def define_has_many_count(name, options, through = nil)
        method_name = name.to_s.singularize.underscore + "_count"
        define_method(method_name) do |*args|
          local_options = args.first && args.first.is_a?(Hash) && args.first
          if local_options
            local_options.assert_valid_keys(:force_reload, :with_deleted)
            forced_reload = local_options[:force_reload]
            with_deleted = local_options[:with_deleted]
          else
            forced_reload = false
            with_deleted = false
          end

          if forced_reload || instance_variable_get("@#{method_name}").nil?
            instance_variable_set("@#{method_name}", count_associated(through || options[:class_name], self.class, :with_deleted => with_deleted, :foreign_key => options[:foreign_key]))
          end
          instance_variable_get("@#{method_name}")
        end
      end
      
      def set_parent_has_many_association_object(parent, child_collection)
        child_collection.each do |child|
          if child.respond_to?("#{parent.class.name.to_s.singularize.downcase}=")
            child.send("#{parent.class.name.to_s.singularize.camelize.downcase}=", parent)
          end
        end
      end
      
      class Property < SimplyStored::Couch::AssociationProperty
        
        def initialize(owner_clazz, name, options = {})
          options = {
            :dependent => :nullify,
            :through => nil,
            :class_name => name.to_s.singularize.camelize,
            :foreign_key => nil
          }.update(options)
          @name, @options = name, options
          
          options.assert_valid_keys(:dependent, :through, :class_name, :foreign_key)
          
          if options[:through]
            owner_clazz.class_eval do
              _define_cache_accessors(name, options)
              define_has_many_through_getter(name, options, options[:through])
              define_has_many_count(name, options, options[:through])
            end
          else
            owner_clazz.class_eval do
              _define_cache_accessors(name, options)
              define_has_many_getter(name, options)
              define_has_many_setter_add(name, options)
              define_has_many_setter_remove(name, options)
              define_has_many_setter_remove_all(name, options)
              define_has_many_count(name, options)
            end
          end
        end
        
      end
    end
  end
end
