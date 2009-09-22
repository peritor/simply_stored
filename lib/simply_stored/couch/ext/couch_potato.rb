module CouchPotato
  class Database
    def save_document(document, validate = true)
      return true unless document.dirty?
      if document.new?
        create_document(document, validate)
      else
        update_document(document, validate)
      end
    end
    
    private
    
    def create_document(document, validate)
      document.database = self
      
      if validate
        document.run_callbacks :before_validation_on_save
        document.run_callbacks :before_validation_on_create
        return unless document.valid?
        document.run_callbacks :before_save
        document.run_callbacks :before_create
      end
      
      res = database.save_doc clean_hash(document.to_hash)
      document._rev = res['rev']
      document._id = res['id']
      document.run_callbacks :after_save
      document.run_callbacks :after_create
      true
    end

    def update_document(document, validate)
      if validate
        document.run_callbacks :before_validation_on_save
        document.run_callbacks :before_validation_on_update
        return unless document.valid?
        document.run_callbacks :before_save
        document.run_callbacks :before_update
      end
      
      res = database.save_doc clean_hash(document.to_hash)
      document._rev = res['rev']
      document.run_callbacks :after_save
      document.run_callbacks :after_update
      true
    end
    
  end
  
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