# frozen_string_literal: true

module WGPU
  module Native
    module EnumHelper
      module_function

      # Converts a symbolic enum member to its integer value.
      # @param enum [FFI::Enum, Hash] enum mapping
      # @param value [Symbol, Integer] member or native value
      # @param name [String] name used in validation errors
      # @return [Integer]
      # @raise [ArgumentError] if the value is invalid
      def coerce(enum, value, name: "enum")
        return value if value.is_a?(Integer)
        raise ArgumentError, "#{name} must be a Symbol or Integer, got #{value.class}" unless value.is_a?(Symbol)

        mapping = mapping_for(enum)
        result = mapping[value]
        return result unless result.nil?

        raise ArgumentError, unknown_value_message(name, value, mapping.keys)
      end

      # Converts symbolic flag names to their combined integer bitset.
      #
      # @param enum [FFI::Enum, Hash] flag mapping
      # @param value [Symbol, Integer, Array<Symbol>] flags to convert
      # @param name [String] name used in validation errors
      # @return [Integer] combined bitset
      # @raise [ArgumentError] if a flag is unknown or has an invalid type
      def coerce_flags(enum, value, name: "flags")
        return value if value.is_a?(Integer)

        values = value.is_a?(Array) ? value : [value]
        unless values.all? { |item| item.is_a?(Symbol) }
          raise ArgumentError, "#{name} must be a Symbol, Integer, or Array of Symbols"
        end

        values.reduce(0) { |flags, item| flags | coerce(enum, item, name:) }
      end

      # Expands a bitset into its independent symbolic flags.
      # @param enum [FFI::Enum, Hash] flag mapping
      # @param value [Integer] combined bitset
      # @return [Array<Symbol>]
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
