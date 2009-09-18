module CouchPotato
  module Persistence
    module DirtyAttributes
      private
      
      def reset_dirty_attributes
        self.class.properties.each do |property|
          if !property.respond_to?(:supports_dirty?) || property.supports_dirty?
            instance_variable_set("@#{property.name}_was", send(property.name))
          end
        end
      end
    end
  end
end