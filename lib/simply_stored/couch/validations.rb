module SimplyStored
  module Couch
    module Validations
      class ValidatesInclusionOf < ::Validatable::ValidationBase
        required_option :in

        def valid?(instance)
          values = instance.send(attribute)
          values = [values] unless values.is_a?(Array)
          self.in & values == values
        end

        def message(instance)
          super || "must be one of #{self.in.join(", ")}"
        end
      end
  
      def validates_inclusion_of(*args)
        add_validations(args, ValidatesInclusionOf)
      end
    end
  end
end

  