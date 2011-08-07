module CouchPotato
  module Persistence
    module DirtyAttributes
      private
      
      def reset_dirty_attributes
        # active mode reset
        @previously_changed = changes
        @changed_attributes.clear
        @forced_dirty = nil

        # belongs_to properties reset
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

module CouchPotato
  class Database

    # the original implementation does not delete if callbacks are skipped
    def destroy_document(document, run_callbacks = true)
      if run_callbacks
        document.run_callbacks :destroy do
          document._deleted = true
          couchrest_database.delete_doc document.to_hash
        end
      else
        document._deleted = true
        couchrest_database.delete_doc document.to_hash
      end
      document._id = nil
      document._rev = nil
    end
  end
end