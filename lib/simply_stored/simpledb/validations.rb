module SimplyStored
  module SimpleDB
    module Validations
      def validate
        # abstract - implement in subclass and add checks that add to errors with add_error
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    
      module ClassMethods
        def require_attributes(*attributes)
          @_required_attributes ||= []
          attributes.each do |attr|
            @_required_attributes << attr.to_s
          end
        end
  
        def require_inclusion_of(attr, valid_set, options = {})
          options = {
            :allow_blank => false
          }.update(options)
          @_required_inclusions ||= {}
          @_required_inclusions[attr.to_s] = [valid_set, options]
        end
  
        def require_format_of(attr, valid_regex, options = {})
          options = {
            :allow_blank => false
          }.update(options)
          @_required_formats ||= {}
          @_required_formats[attr.to_s] = [valid_regex, options]
        end
      end
    
      def ensure_formats
        list_of_format_checks = self.class.instance_variable_get("@_required_formats") || {}
        list_of_format_checks.each do |attr, check_options|
          valid_regex, options = check_options
          add_error(attr, 'is of invalid format') unless valid_regex.match(self.send(attr)) || (self.send(attr).blank? && options[:allow_blank])
        end
      end
  
      def ensure_inclusions
        list_of_inclusion_checks = self.class.instance_variable_get("@_required_inclusions") || {}
        list_of_inclusion_checks.each do |attr, check_options|
          valid_set, options = check_options
          if self.send(attr) && self.send(attr).is_a?(Array)
            self.send(attr).all? do |item|
              add_error(attr, 'is not included in the valid set') unless (valid_set.include?(item) rescue false) || (self.send(attr).blank? && options[:allow_blank])
            end
          else
            add_error(attr, 'is not included in the valid set') unless (valid_set.include?(self.send(attr)) rescue false) || (self.send(attr).blank? && options[:allow_blank])
          end
        end
      end

      def add_error(attr, desc)
        errors << [attr, desc]
      end
  
      def clear_errors
        @errors = []
      end
  
      def ensure_no_foreign_attributes
        not_allowed_attributes = self.attributes.keys.sort - (self.class.instance_variable_get("@_defined_attributes") || [])
        not_allowed_attributes = not_allowed_attributes.delete_if{|attr| attr.to_s == 'id'} # the ID is an implicit attribute
        not_allowed_attributes.each do |attr|
          add_error(attr, 'is unknown and should not be set')
        end
      end
  
      def ensure_required_attributes_present
        list_of_required_attributes = self.class.instance_variable_get("@_required_attributes") || []
        list_of_required_attributes.all? do |attr| 
          if self.send(attr).blank?
            add_error(attr, 'is missing')
            false
          else
            true
          end
        end
      end
    end
  end
end