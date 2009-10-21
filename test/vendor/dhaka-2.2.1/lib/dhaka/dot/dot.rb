module Dhaka
  module Dot #:nodoc:
    class Digraph #:nodoc:
      def initialize(node_attributes = {})
        @result = ["digraph x {"]
        @result << %(node #{dotify_hash(node_attributes)})
        yield(self)
        @result << '}'
      end

      def node(obj, attributes = {})
        @result << "#{obj.object_id} #{dotify_hash(attributes)}"
      end

      def edge(src, dest, attributes = {})
        @result << "#{src.object_id} -> #{dest.object_id} #{dotify_hash(attributes)}"
      end

      def dotify_hash hash
        sorted_key_value_pairs = hash.collect {|key, value| [key.to_s, value.to_s]}.sort
        hash.empty? ? "" : '[' + sorted_key_value_pairs.collect {|key, value| "#{key}=#{value.to_s.inspect}"}.join(' ') + ']'
      end

      def to_dot
        @result.join("\n")
      end
    end
  end
end