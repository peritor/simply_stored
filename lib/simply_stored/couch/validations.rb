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
      end
  
      def validates_inclusion_of(*args)
        add_validations(args, ValidatesInclusionOf)
      end
      
      def validates_format_of(*args)
        add_validations(args, ValidatesFormatOf)
      end
    end
  end
end

  