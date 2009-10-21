module SimplyStored
  module SimpleDB
    module Attributes
      def self.included(base)
        base.extend(ClassMethods)
      end
    
      module ClassMethods
        # generates an accessor for a simple attribute
        def simpledb_string(*attributes)
          attributes.each do |attr|
            # getter
            define_method attr.to_s do
              self[attr.to_s].try(:first) || @_partitioned_attributes.try(:[], attr.to_s)
            end
      
            # setter
            define_method "#{attr}=" do |val|
              self[attr.to_s] = val
            end
      
            add_attribute_definition_to_attribute_list(attr)
            add_attribute_definition_to_partition_list(attr)
          end
        end
  
        def simpledb_array(*attributes)
          attributes.each do |attr|
            # getter
            define_method attr.to_s do
              self[attr.to_s] = [] unless self[attr.to_s]
              self[attr.to_s]
            end
      
            # setter
            define_method "#{attr}=" do |val|
              self[attr.to_s] = [val].flatten
            end
      
            add_attribute_definition_to_attribute_list(attr)
          end
        end
  
        def simpledb_timestamp(*attributes)
          attributes.each do |attr|
            # getter
            define_method attr.to_s do
              if self[attr.to_s]
                cached = instance_variable_get("@#{attr}")
                if cached
                  return cached
                else
                  val = Time.parse(self[attr.to_s].first + "+0000").utc # UTC
                  instance_variable_set("@#{attr}", val)
                  return val
                end
              else
                nil
              end
            end
      
            # setter
            define_method "#{attr}=" do |val|
              instance_variable_set("@#{attr}", val)
              self[attr.to_s] = val.strftime("%Y%m%d%H%M%S")
            end
      
            add_attribute_definition_to_attribute_list(attr)
          end
        end
  
        def simpledb_integer(*attributes)
          attributes.each do |attr|
            # getter
            define_method attr.to_s do
              if self[attr.to_s]
                cached = instance_variable_get("@#{attr}")
                if cached
                  return cached
                else
                  val = self[attr.to_s].first.sub(/\A0+/, '').to_i
                  instance_variable_set("@#{attr}", val)
                  return val
                end
              else
                nil
              end
            end
      
            # setter
            define_method "#{attr}=" do |val|
              instance_variable_set("@#{attr}", val)
              self[attr.to_s] = sprintf("%016d", val.to_i)
            end
      
            add_attribute_definition_to_attribute_list(attr)
          end
        end
  
        def add_attribute_definition_to_attribute_list(attr)
          @_defined_attributes ||= []
          @_defined_attributes << attr.to_s
        end

        def add_attribute_definition_to_partition_list(attr)
          @_partitioned_attributes ||= []
          @_partitioned_attributes << attr.to_s
        end
      
        def attr_protected(*args)
          @_protected_attributes ||= []
          @_protected_attributes += args.to_a
        end
      
        def attr_accessible(*args)
          @_accessible_attributes ||= []
          @_accessible_attributes += args.to_a
        end
      
      end
    
      def attributes=(attr)
        attr = _remove_protected_attributes(attr)
        super(attr)
      end
    
      def _remove_protected_attributes(attrs)
        return {} if attrs.blank?
        attrs = attrs.dup.stringify_keys
        (self.class.instance_variable_get(:@_protected_attributes) || []).map(&:to_s).each do |protected_attribute|
          attrs.delete(protected_attribute)
        end
      
        accessible_attributes = (self.class.instance_variable_get(:@_accessible_attributes) || []).map(&:to_s)

        if accessible_attributes.present?
          attrs.each do |attr_key, attr_value|
            attrs.delete(attr_key) unless accessible_attributes.include?(attr_key)
          end
        end
      
        attrs
      end
    
      def partition_string_attributes
        (self.class.instance_variable_get(:@_partitioned_attributes) || []).each do |attr|
          next if self[attr].nil?
          value = self[attr].first
          if value.present? && value.size > 1024
            0.upto(value.size / 1024) do |i|
              self["#{attr.to_s}_#{i}"] = value[(1024 * i)..(1024 * (i + 1) - 1)]
            end
            @_partitioned_attributes ||= {}
            @_partitioned_attributes[attr] = self[attr]
            send("#{attr}=", [])
          end
        end
      end

      def restore_partitioned_attributes
        (self.class.instance_variable_get(:@_partitioned_attributes) || []).each do |attr|
          if (partitions = attributes.select{|key, value| key.match(/^#{attr}_([0-9]+)$/)}).any?
            unpartitioned_value = ""
            partitions.sort_by{|key, value| key.match(/^#{attr}_([0-9]+)$/); $1}.each do |partition|
              unpartitioned_value << partition.last.first
            end
            self[attr] = unpartitioned_value
          end
        end
      end
    end
  end
end