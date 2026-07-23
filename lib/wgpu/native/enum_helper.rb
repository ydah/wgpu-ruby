# frozen_string_literal: true

module WGPU
  module Native
    module EnumHelper
      module_function

      def coerce(enum, value, name: "enum")
        return value if value.is_a?(Integer)
        raise ArgumentError, "#{name} must be a Symbol or Integer, got #{value.class}" unless value.is_a?(Symbol)

        mapping = mapping_for(enum)
        result = mapping[value]
        return result unless result.nil?

        raise ArgumentError, unknown_value_message(name, value, mapping.keys)
      end

      def coerce_flags(enum, value, name: "flags")
        return value if value.is_a?(Integer)

        values = value.is_a?(Array) ? value : [value]
        unless values.all? { |item| item.is_a?(Symbol) }
          raise ArgumentError, "#{name} must be a Symbol, Integer, or Array of Symbols"
        end

        values.reduce(0) { |flags, item| flags | coerce(enum, item, name:) }
      end

      def decompose_flags(enum, value)
        raise ArgumentError, "flag value must be an Integer" unless value.is_a?(Integer)

        mapping = mapping_for(enum)
        return [:none] if value.zero? && mapping.key?(:none)

        mapping.filter_map do |symbol, bit|
          symbol if bit.positive? && power_of_two?(bit) && (value & bit) == bit
        end
      end

      def mapping_for(enum)
        mapping = enum.respond_to?(:to_h) ? enum.to_h : enum
        unless mapping.respond_to?(:key?) && mapping.respond_to?(:keys)
          raise ArgumentError, "enum must be an FFI::Enum or Hash"
        end

        mapping
      end
      private_class_method :mapping_for

      def unknown_value_message(name, value, candidates)
        formatted = candidates.grep(Symbol).sort.map(&:inspect).join(", ")
        "Unknown #{name} #{value.inspect}. Valid values: #{formatted}"
      end
      private_class_method :unknown_value_message

      def power_of_two?(value)
        (value & (value - 1)).zero?
      end
      private_class_method :power_of_two?
    end
  end
end
