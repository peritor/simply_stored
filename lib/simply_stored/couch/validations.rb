module SimplyStored
  module Couch
    module Validations
      class ValidatesInclusionOf < ::Validatable::ValidationBase
        required_option :in
        option :allow_blank
        
        def valid?(instance)
          if self.allow_blank && instance.send(attribute).blank?
            true
          else
            values = instance.send(attribute)
            values = [values] unless values.is_a?(Array)
            values.select{|value|
              !self.in.include?(value)
            }.empty?
          end
        end

        def message(instance)
          super || "must be one or more of #{self.in.join(", ")}"
        end
      end
  
      class ValidatesFormatOf < ::Validatable::ValidationBase #:nodoc:
        required_option :with
        option :allow_blank

        def valid?(instance)
          (allow_blank && instance.send(attribute).blank?) ||
            !(instance.send(self.attribute).to_s =~ self.with).nil?
        end

        def message(instance)
          super || "is invalid"
        end
        
        def i18n
          super || "#{i18n_prefix}.invalid"
        end
      end
  
      class ValidatesUniquenessOf < ::Validatable::ValidationBase
        def valid?(instance)
          other_instance = instance.class.send("find_by_#{attribute}", instance.send(attribute))
          if other_instance && other_instance != instance &&
              other_instance.send(attribute) == instance.send(attribute)
            false
          else
            true
          end
        end
        
        def message(instance)
          super || "#{attribute.to_s.try(:humanize) || attribute.to_s} is already taken"
        end
        
        def i18n
          super || "#{i18n_prefix}.not_unique"
        end
      end
      
      def validates_inclusion_of(*args)
        add_validations(args, ValidatesInclusionOf)
      end
      
      def validates_format_of(*args)
        add_validations(args, ValidatesFormatOf)
      end
      
      def validates_uniqueness_of(*args)
        args.each do |name|
          if not respond_to?("by_#{name}")
            view "by_#{name}", :key => name
          end
        end
        
        add_validations(args, ValidatesUniquenessOf)
      end
    end
  end
end

  
