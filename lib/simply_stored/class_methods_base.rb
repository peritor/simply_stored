module SimplyStored
  module ClassMethods
    module Base
      def get_class_from_name(klass_name)
        klass_name.to_s.gsub('__','/').gsub('__','::').classify.constantize
      end
      
      def foreign_key
        name.underscore.gsub('/','__').gsub('::','__') + "_id"
      end
      
      def attr_protected(*args)
        @_protected_attributes ||= []
        @_protected_attributes += args.to_a
      end
      
      def attr_accessible(*args)
        @_accessible_attributes ||= []
        @_accessible_attributes += args.to_a
      end
    end
  end
end