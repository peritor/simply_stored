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
  
      def validates_inclusion_of(*args)
        add_validations(args, ValidatesInclusionOf)
      end
    end
  end
end

  