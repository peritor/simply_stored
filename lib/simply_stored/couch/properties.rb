module SimplyStored
  module Couch
    module Properties
      def check_existing_properties(name, type)
        if properties.find{|property| name.to_sym == property.name.to_sym && property.class != type}
          raise "Property with the name (#{name}) already defined"
        end
      end
    end
  end
end
