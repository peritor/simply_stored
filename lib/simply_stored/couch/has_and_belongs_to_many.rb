module SimplyStored
  module Couch
    module HasAndBelongsToMany
      def has_and_belongs_to_many(name, options = {})
        check_existing_properties(name, SimplyStored::Couch::HasAndBelongsToMany::Property)
        properties << SimplyStored::Couch::HasAndBelongsToMany::Property.new(self, name, options)
      end

      def define_has_and_belongs_to_many_property(foreign_key)
        property foreign_key
      end

      def define_has_and_belongs_to_many_views(name, options)
        key_order = options[:class_storing_keys] == self.name ? "doc.#{options[:foreign_key]}[index], doc._id" : "doc._id, doc.#{options[:foreign_key]}[index]"
        value = options[:class_storing_keys] == self.name ? 1 : "{ _id :doc.#{options[:foreign_key]}[index]}"

        map_definition_without_deleted = <<-eos
          function(doc) {
            if (doc['ruby_class'] == '#{options[:class_storing_keys]}' && doc['#{options[:foreign_key]}'] != null) {
              if (doc['#{soft_delete_attribute}'] && doc['#{soft_delete_attribute}'] != null){
                // "soft" deleted
              }else{
                for (var index in doc.#{options[:foreign_key]}) {
                  emit([#{key_order}], #{value});
                }
              }
            }
          }
        eos

        reduce_definition = options[:class_storing_keys] == self.name ? "_sum" : <<-eos
          function(key, values) {
            var sum = 0;
            for (var i in values){
              if (typeof(i) == 'number'){
                sum = sum + i;
              } else {
                sum = sum + 1;
              }
            }
            return sum;
          }
        eos

        view "association_#{self.name.underscore}_has_and_belongs_to_many_#{name}",
          :map => map_definition_without_deleted,
          :reduce => reduce_definition,
          :type => "custom",
          :include_docs => true

        map_definition_with_deleted = <<-eos
          function(doc) {
            if (doc['ruby_class'] == '#{options[:class_storing_keys]}' && doc['#{options[:foreign_key]}'] != null) {
              for (var index in doc.#{options[:foreign_key]}) {
                emit([#{key_order}], #{value});
              }
            }
          }
        eos

        view "association_#{self.name.underscore}_has_and_belongs_to_many_#{name}_with_deleted",
          :map => map_definition_with_deleted,
          :reduce => reduce_definition,
          :type => "custom",
          :include_docs => true
      end

      def define_has_and_belongs_to_many_getter(name, options)
        define_method(name) do |*args|
          local_options = args.first && args.first.is_a?(Hash) && args.first
          forced_reload, with_deleted, limit, descending = extract_association_options(local_options)

          cached_results = send("_get_cached_#{name}")
          cache_key = _cache_key_for(local_options)
          if forced_reload || cached_results[cache_key].nil?
            cached_results[cache_key] = find_associated_via_join_view(options[:class_name], self.class, :with_deleted => with_deleted, :limit => limit, :descending => descending, :foreign_key => options[:foreign_key])
            instance_variable_set("@#{name}", cached_results)
          end
          cached_results[cache_key]
        end
      end

      def define_has_and_belongs_to_many_setter_add(name, options)
        define_method("add_#{name.to_s.singularize}") do |value|
          klass = self.class.get_class_from_name(name)
          raise ArgumentError, "expected #{klass} got #{value.class}" unless value.is_a?(klass)

          if options[:class_storing_keys] == self.class.name
            self.send("#{options[:foreign_key]}=", ((send(options[:foreign_key]) || []) + [value.id]).uniq )
            self.save(false)
          else
            value.send("#{options[:foreign_key]}=", ((value.send(options[:foreign_key]) || []) + [self.id]).uniq )
            value.save(false)
          end

          cached_results = send("_get_cached_#{name}")[:all]
          send("_set_cached_#{name}", (cached_results || []) << value, :all)
          nil
        end
      end

      def define_has_and_belongs_to_many_setter_remove(name, options)
        define_method "remove_#{name.to_s.singularize}" do |value|
          klass = self.class.get_class_from_name(name)
          raise ArgumentError, "expected #{klass} got #{value.class}" unless value.is_a?(klass)

          if options[:class_storing_keys] == self.class.name
            raise ArgumentError, "cannot remove not mine" unless (send(options[:foreign_key]) || []).include?(value.id)
          else
            raise ArgumentError, "cannot remove not mine" unless (value.send(options[:foreign_key]) || []).include?(id)
          end
      
          if options[:class_storing_keys] == self.class.name
            foreign_keys = (send(options[:foreign_key]) || []) - [value.id]
            send("#{options[:foreign_key]}=", foreign_keys)
            save(false)
          else
            foreign_keys = (value.send(options[:foreign_key]) || []) - [self.id]
            value.send("#{options[:foreign_key]}=", foreign_keys)
            value.save(false)
          end
      
          cached_results = send("_get_cached_#{name}")[:all]
          send("_set_cached_#{name}", (cached_results || []).delete_if{|item| item.id == value.id}, :all)
          nil
        end
      end
      
      def define_has_and_belongs_to_many_setter_remove_all(name, options)
        define_method "remove_all_#{name}" do
          all = send("#{name}", :force_reload => true)
      
          all.collect{|i| i}.each do |item|
            send("remove_#{name.to_s.singularize}", item)
          end
        end
      end
      
      def define_has_and_belongs_to_many_count(name, options, through = nil)
        method_name = name.to_s.singularize.underscore + "_count"
        define_method(method_name) do |*args|
          local_options = args.first && args.first.is_a?(Hash) && args.first
          forced_reload, with_deleted, limit, descending = extract_association_options(local_options)

          if forced_reload || instance_variable_get("@#{method_name}").nil?
            instance_variable_set("@#{method_name}", count_associated_via_join_view(through || options[:class_name], self.class, :with_deleted => with_deleted, :foreign_key => options[:foreign_key]))
          end
          instance_variable_get("@#{method_name}")
        end
      end

      def define_cache_accessors(name, options)
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
      
      def define_has_and_belongs_to_many_after_destroy_cleanup(name, options)
        if options[:class_storing_keys] == self.name
          define_method "has_and_belongs_to_many_clean_up_after_destroy" do |property|
            nil # deleting is enough as we store the keys
          end
        else
          define_method "has_and_belongs_to_many_clean_up_after_destroy" do |property|
            send("remove_all_#{property.name}")
          end
        end
      end

      class Property < SimplyStored::Couch::AssociationProperty

        def initialize(owner_clazz, name, options = {})
          options = {
            :storing_keys => false,
            :class_name => name.to_s.singularize.camelize,
            :foreign_key => nil,
          }.update(options)

          # there is only one pair of foreign_keys and it usualy the name of the class not storing the keys
          if options[:foreign_key].blank?
            if options[:storing_keys]
              options[:foreign_key] = options[:class_name].singularize.underscore.foreign_key.pluralize
            else
              options[:foreign_key] = owner_clazz.name.singularize.underscore.foreign_key.pluralize
            end
          end
          options[:class_storing_keys] = options[:storing_keys] ? owner_clazz.name : options[:class_name]
          @name, @options = name, options

          options.assert_valid_keys(:class_name, :foreign_key, :storing_keys, :class_storing_keys)

          owner_clazz.class_eval do
            define_cache_accessors(name, options)
            define_has_and_belongs_to_many_property(options[:foreign_key]) if options[:storing_keys]
            define_has_and_belongs_to_many_views(name, options)
            define_has_and_belongs_to_many_getter(name, options)
            define_has_and_belongs_to_many_setter_add(name, options)
            define_has_and_belongs_to_many_setter_remove(name, options)
            define_has_and_belongs_to_many_setter_remove_all(name, options)
            define_has_and_belongs_to_many_count(name, options)
            define_has_and_belongs_to_many_after_destroy_cleanup(name, options)
          end
        end

      end
    end
  end
end
