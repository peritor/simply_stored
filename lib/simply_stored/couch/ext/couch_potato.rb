module CouchPotato
  module Persistence
    module DirtyAttributes
      private
      
      def reset_dirty_attributes
        self.class.properties.each do |property|
          if !property.respond_to?(:supports_dirty?) || property.supports_dirty?
            property.respond_to?(:reset_dirty_attribute) ? property.reset_dirty_attribute(self) :
              instance_variable_set("@#{property.name}_was", send(property.name))
          end
        end
      end
    end
  end
end