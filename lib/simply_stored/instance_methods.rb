module SimplyStored
  module InstanceMethods
    
    def initialize(attributes = {})
      super(_remove_protected_attributes(attributes))
    end
    
    def ==(other)
      other._id == _id && other._rev == _rev
    end

    def eql?(other)
      self.==(other)
    end

    def save(validate = true)
      CouchPotato.database.save_document(self, validate)
    end

    def save!
      CouchPotato.database.save_document!(self)
    end

    def destroy
      check_and_destroy_dependents
      CouchPotato.database.destroy_document(self)
      freeze
    end
    alias :delete :destroy

    def update_attributes(attributes = {})
      self.attributes = attributes
      save
    end
    
    def attributes=(attr)
      super(_remove_protected_attributes(attr))
    end

    def reload
      instance = self.class.find(_id)
      instance.attributes.each do |attribute, value|
        send "#{attribute}=", value
      end
      self._rev = instance._rev
      reset_dirty_attributes
      reset_association_caches
      self
    end
    
    protected
    
    def reset_association_caches
      self.class.properties.each do |property|
        if property.respond_to?(:association?) && property.association?
          instance_variable_set("@#{property.name}", nil)
        end
      end
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
    
    def check_and_destroy_dependents
      self.class.properties.each do |property|
        if property.respond_to?(:association?) and property.association?
          next unless property.options[:dependent]
          next if property.options[:through]
          dependents = send(property.name, :force_reload => true)
          dependents = [dependents] unless dependents.is_a?(Array)
          dependents.reject{|d| d.nil?}.each do |dependent|
            case property.options[:dependent]
            when :destroy
              dependent.destroy
            else
              dependent.send("#{self.class.foreign_property}=", nil)
              dependent.save
            end
          end
        end
      end
    end
    
    def find_one_associated(from, to)
      find_associated(from, to, :limit => 1, :descending => true).first
    end
    
    def find_associated(from, to, options = {})
      CouchPotato.database.view(
        self.class.get_class_from_name(from).send(
          "association_#{from.to_s.singularize.underscore}_belongs_to_#{to.name.singularize.underscore}", :key => id))
    end
    
  end
end