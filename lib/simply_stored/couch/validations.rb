module SimplyStored
  module Couch
    module Validations

      def validates_uniqueness_of(*attr_names)
        attr_names.each do |name|
          if not respond_to?("by_#{name}")
            view "by_#{name}", :key => name
          end
        end

        validates_with ValidatesUniquenessOf, _merge_attributes(attr_names)
      end

      def validates_inclusion_of(*attr_names)
        validates_with ValidatesInclusionOf, _merge_attributes(attr_names)
      end

      class ValidatesUniquenessOf < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          other_record = record.class.send("find_by_#{attribute}", record.send(attribute))
          if other_record && other_record != record &&
              other_record.send(attribute) == record.send(attribute)
            record.errors.add(attribute, :taken)
          else
            true
          end
        end
      end

      class ValidatesInclusionOf < ::ActiveModel::Validations::InclusionValidator
        def validate_each(record, attribute, value)
          delimiter = options[:in]
          exclusions = delimiter.respond_to?(:call) ? delimiter.call(record) : delimiter
          if value.is_a?(Array)
            values = value
          else
            values = [value]
          end

          values.each do |value|
            unless exclusions.send(inclusion_method(exclusions), value)
              record.errors.add(attribute, :inclusion, options.except(:in).merge!(:value => value))
            end
          end
        end
      end

    end
  end
end



