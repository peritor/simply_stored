module SimplyStored
  module InstanceMethods
    
    def initialize(attributes = {}, &blk)
      super(_remove_protected_attributes(attributes))
      blk.call(self) if blk
    end
    
    def ==(other)
      other.kind_of?(SimplyStored::Couch) && other._id == _id && other._rev == _rev
    end

    def eql?(other)
      self.==(other)
    end

    def save(validate = true)
      retry_on_conflict do
        CouchPotato.database.save_document(self, validate)
      end
    end

    def save!
      retry_on_conflict do
        CouchPotato.database.save_document!(self)
      end
    end

    def destroy(override_soft_delete=false)
      check_and_destroy_dependents
      if self.class.soft_deleting_enabled? && !override_soft_delete
        _mark_as_deleted
      else
        self.skip_callbacks = true if self.class.soft_deleting_enabled? && deleted?
        CouchPotato.database.destroy_document(self)
        freeze
      end
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
      instance = self.class.find(_id, :with_deleted => true)
      instance.attributes.each do |attribute, value|
        send "#{attribute}=", value
      end
      self._rev = instance._rev
      reset_dirty_attributes
      reset_association_caches
      self
    end
    
    def deleted?
      if self.class.soft_deleting_enabled?
        !send(self.class.soft_delete_attribute).nil?
      else
        false
      end
    end
    
    protected
    
    def retry_on_conflict(max_retries = 2, &blk)
      retry_count = 0
      begin
        blk.call
      rescue RestClient::Exception, RestClient::Conflict => e
        if (e.http_code == 409 || e.is_a?(RestClient::Conflict)) && self.class.auto_conflict_resolution_on_save && retry_count < max_retries && try_to_merge_conflict
          retry_count += 1
          retry
        else
          raise e
        end
      end
    end
    
    def try_to_merge_conflict
      original = self.class.find(id)
      our_attributes = self.attributes.dup
      their_attributes = original.attributes.dup
      [:updated_at, :created_at, :id, :rev, :_id, :_rev].each do |skipped_attribute|
        our_attributes.delete(skipped_attribute)
        their_attributes.delete(skipped_attribute)
      end
      if _merge_possible?(our_attributes, their_attributes)
        _copy_non_conflicting_attributes(our_attributes, their_attributes)
        self._rev = original._rev
        true
      else
        false
      end
    end
    
    def _copy_non_conflicting_attributes(our_attributes, their_attributes)
      their_attributes.each do |attr_name, their_value|
        if !self.send("#{attr_name}_changed?") && our_attributes[attr_name] != their_value
          self.send("#{attr_name}=", their_value)
        end
      end
    end
    
    def _merge_possible?(our_attributes, their_attributes)
      their_attributes.all? do |attr_name, their_value|
        our_attributes[attr_name] == their_value || # same
        !self.send("#{attr_name}_changed?") || # we didn't change
        self.send("#{attr_name}_changed?") && their_value == self.send("#{attr_name}_was") # we changed and they kept the original
      end
    end
    
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
            when :ignore
              # skip
            else 
              # nullify
              unless dependent.class.soft_deleting_enabled?
                dependent.send("#{self.class.foreign_property}=", nil)
                dependent.save(false)
              end
            end
          end
        end
      end
    end
    
    def find_one_associated(from, to, options = {})
      options = {
        :limit => 1, 
        :descending => true
      }.update(options)
      find_associated(from, to, options).first
    end
    
    def find_associated(from, to, options = {})
      foreign_key = (options.delete(:foreign_key) || self.class.name.singularize.underscore.foreign_key ).gsub(/_id$/, '')
      view_options = {}
      view_options[:reduce] = false
      view_options[:descending] = options[:descending] if options[:descending]
      if view_options[:descending]
        view_options[:startkey] = ["#{id}\u9999"]
        view_options[:endkey] = [id]
      else
        view_options[:startkey] = [id]
        view_options[:endkey] = ["#{id}\u9999"]
      end
      view_options[:limit] = options[:limit] if options[:limit]
      if options[:with_deleted]
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_belongs_to_#{foreign_key}_with_deleted", view_options))
      else
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_belongs_to_#{foreign_key}", view_options))
      end
    end
    
    def count_associated(from, to, options = {})
      view_options = {}
      view_options[:reduce] = true
      view_options[:include_docs] = false
      view_options[:startkey] = [id]
      view_options[:endkey] = ["#{id}\u9999"]
      if options[:with_deleted]
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_belongs_to_#{to.name.singularize.underscore}_with_deleted", view_options))
      else
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_belongs_to_#{to.name.singularize.underscore}", view_options))
      end
    end
    
    def _mark_as_deleted
      run_callbacks(:before_destroy)
      send("#{self.class.soft_delete_attribute}=", Time.now)
      save(false)
      run_callbacks(:after_destroy)
    end
    
  end
end