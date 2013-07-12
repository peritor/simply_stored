module SimplyStored
  module InstanceMethods

    def self.included(base) #:nodoc:
      base.send :include, ActiveModel::Conversion
    end

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
        retry_on_connection_error do
          CouchPotato.database.save_document(self, validate)
        end
      end
    end

    def save!
      retry_on_conflict do
        retry_on_connection_error do
          CouchPotato.database.save_document!(self)
        end
      end
    end

    def destroy(override_soft_delete=false)
      check_and_destroy_dependents
      if self.class.soft_deleting_enabled? && !override_soft_delete
        # soft-delete
        _mark_as_deleted
      else
        if self.class.soft_deleting_enabled? && deleted?
          # really deleting a previously soft-deleted object - skipping callbacks
          CouchPotato.database.destroy_document(self, false)
        else # deleting a normal object or a soft-deletable object that was not soft-deleted before
          CouchPotato.database.destroy_document(self, true)
        end
        freeze
      end
      self
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
      CouchPotato.database.invalidate_cached_results(self)
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

    def retry_on_connection_error(max_retries = 2, &blk)
      retry_count = 0
      begin
        blk.call
      rescue Errno::ECONNREFUSED => e
        if retry_count < max_retries
          retry_count += 1
          retry
        else
          raise e
        end
      end
    end

    def retry_on_conflict(max_retries = 2, &blk)
      retry_count = 0
      begin
        _reset_conflict_information
        blk.call
      rescue RestClient::Exception, RestClient::Conflict => e
        if (e.http_code == 409 || e.is_a?(RestClient::Conflict)) && self.class.auto_conflict_resolution_on_save && retry_count < max_retries && try_to_merge_conflict
          retry_count += 1
          retry
        else
          _decorate_with_conflict_details(e) if e.is_a?(RestClient::Conflict)
          raise e
        end
      end
    end

    def _decorate_with_conflict_details(exception)
      if @_conflict_information.present?
        def exception.metaclass
          class << self
            self
          end
        end
        local_conflict_information = @_conflict_information
        exception.metaclass.send(:define_method, :message){ "409 Conflict - conflict on attributes: #{local_conflict_information.inspect}" }
      end
    end

    def try_to_merge_conflict
      original = self.class.find(id)
      our_attributes = self.attributes.dup
      their_attributes = original.attributes.dup
      _clear_non_relevant_attributes(our_attributes)
      _clear_non_relevant_attributes(their_attributes)
      if _merge_possible?(our_attributes, their_attributes)
        _copy_non_conflicting_attributes(our_attributes, their_attributes)
        self._rev = original._rev
        true
      else
        @_conflict_information = _conflicting_attributes(our_attributes, their_attributes)
        false
      end
    end

    def _reset_conflict_information
      @_conflict_information = nil
    end

    def _clear_non_relevant_attributes(attr_list)
      [:updated_at, :created_at, :id, :rev, :_id, :_rev].each do |skipped_attribute|
        attr_list.delete(skipped_attribute)
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
      _conflicting_attributes(our_attributes, their_attributes).empty?
    end

    def _conflicting_attributes(our_attributes, their_attributes)
      their_attributes.keys.delete_if do |attr_name|
        _attribute_not_in_conflict?(attr_name, our_attributes[attr_name], their_attributes[attr_name])
      end
    end

    def _attribute_not_in_conflict?(attr_name, our_value, their_value)
      our_value == their_value || # same
      !self.send("#{attr_name}_changed?") || # we didn't change
      self.send("#{attr_name}_changed?") && their_value == self.send("#{attr_name}_was") # we changed and they kept the original
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
          if property.is_a?(SimplyStored::Couch::HasAndBelongsToMany::Property)
            has_and_belongs_to_many_clean_up_after_destroy(property)
          else
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
                unless dependent.class.soft_deleting_enabled? && dependent.deleted?
                  dependent.send("#{self.class.foreign_property}=", nil)
                  dependent.save(false)
                end
              end
            end
          end
        end
      end
    end
    
    def _default_view_options(options = {})
      view_options = {:include_docs => true, :reduce => false}
      view_options[:descending] = options[:descending] if options[:descending]
      if view_options[:descending]
        view_options[:startkey] = ["#{id}\u9999"]
        view_options[:endkey] = [id]
      else
        view_options[:startkey] = [id]
        view_options[:endkey] = ["#{id}\u9999"]
      end
      view_options[:skip] = options[:skip] if options[:skip]
      view_options[:limit] = options[:limit] if options[:limit]
      view_options
    end

    def find_one_associated(from, to, options = {})
      options = {
        :limit => 1, 
        :descending => true
      }.update(options)
      find_associated(from, to, options).first
    end
    
    def find_associated(from, to, options = {})

      pagination_params = {}
      if from.is_a?(String) and from.constantize.ancestors.include? SimplyStored::Couch::Paginator
        pagination_params = from.constantize.build_pagination_params
        options.merge!(pagination_params)
      end
      foreign_key = (options.delete(:foreign_key) || self.class.name.singularize.underscore.foreign_key ).gsub(/_id$/, '')
      view_options = _default_view_options(options)
      if options[:with_deleted]
        results = CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_belongs_to_#{foreign_key}_with_deleted", view_options))
 
        SimplyStored::Couch::Helper.eager_load(results, options[:eager_load]) if options[:eager_load]

        unless pagination_params.empty?
          SimplyStored::Couch::Helper.paginate(results, pagination_params)
        else
          results
        end
      else
        results = CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_belongs_to_#{foreign_key}", view_options))
        
        SimplyStored::Couch::Helper.eager_load(results, options[:eager_load]) if options[:eager_load]

        unless pagination_params.empty?
          SimplyStored::Couch::Helper.paginate(results, pagination_params)
        else
          results
        end
      end
    end
    
    def count_associated(from, to, options = {})
      view_options = _default_view_options(options)
      view_options[:reduce] = true
      view_options[:include_docs] = false

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
    
    def find_associated_via_join_view(from, to, options = {})
      foreign_key = options.delete(:foreign_key).gsub(/_ids$/, '').pluralize
      view_options = _default_view_options(options)

      if options[:with_deleted]
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_has_and_belongs_to_many_#{to.to_s.pluralize.underscore}_with_deleted", view_options))
      else
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_has_and_belongs_to_many_#{to.to_s.pluralize.underscore}", view_options))
      end
    end
    
    def count_associated_via_join_view(from, to, options = {})
      view_options = _default_view_options(options)
      view_options[:reduce] = true
      view_options[:include_docs] = false

      if options[:with_deleted]
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_has_and_belongs_to_many_#{to.to_s.pluralize.underscore}_with_deleted", view_options))
      else
        CouchPotato.database.view(
          self.class.get_class_from_name(from).send(
            "association_#{from.to_s.singularize.underscore}_has_and_belongs_to_many_#{to.to_s.pluralize.underscore}", view_options))
      end
    end

    def _mark_as_deleted
      _run_destroy_callbacks do
        send("#{self.class.soft_delete_attribute}=", Time.now)
        save(false)
      end
    end
    
  end
end