module SimplyStored
  module Couch
    module Validations
      class ValidatesInclusionOf < ::Validatable::ValidationBase
        required_option :in

        def valid?(instance)
          values = instance.send(attribute)
          values = [values] unless values.is_a?(Array)
          values.select{|value|
            !self.in.include?(value)
          }.empty?
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

  