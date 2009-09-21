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
      CouchPotato.database.save_document(self)
    end

    def save!
      CouchPotato.database.save_document!(self)
    end

    def destroy
      CouchPotato.database.destroy_document(self)
    end

    def update_attributes(attributes = {})
      self.attributes = attributes
      save
    end
    
    def attributes=(attr)
      super(_remove_protected_attributes(attr))
    end
    
    protected
    
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
    
  end
end