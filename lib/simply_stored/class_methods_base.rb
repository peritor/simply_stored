module SimplyStored
  module ClassMethods
    module Base
      def get_class_from_name(klass_name)
        klass_name.to_s.gsub('__','/').gsub('__','::').classify.constantize
      end
      
      def foreign_key
        name.underscore.gsub('/','__').gsub('::','__') + "_id"
      end
      
    end
  end
end