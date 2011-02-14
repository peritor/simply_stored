module SimplyStored
  module Couch
    class AssociationProperty
      attr_reader :name, :options

      def dirty?(object)
        false
      end

      def build(object, json)
      end

      def serialize(json, object)
      end
      alias :value :serialize

      def supports_dirty?
        false
      end

      def association?
        true
      end

    end
  end
end
