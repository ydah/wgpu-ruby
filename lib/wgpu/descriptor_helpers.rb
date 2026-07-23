# frozen_string_literal: true

module WGPU
  module DescriptorHelpers
    SIZE_MAX = (1 << (FFI.type_size(:size_t) * 8)) - 1

    module_function

    def set_label(descriptor, label, keepalive:)
      if label
        pointer = FFI::MemoryPointer.from_string(label)
        keepalive << pointer
        descriptor[:label][:data] = pointer
        descriptor[:label][:length] = label.bytesize
      else
        descriptor[:label][:data] = nil
        descriptor[:label][:length] = 0
      end
    end

    def uint32_array(values, keepalive:)
      return nil if values.empty?

      pointer = FFI::MemoryPointer.new(:uint32, values.length)
      pointer.write_array_of_uint32(values)
      keepalive << pointer
      pointer
    end

    def set_nullable_string_view(string_view, value, keepalive:)
      if value.nil?
        string_view[:data] = nil
        string_view[:length] = SIZE_MAX
        return
      end

      string = value
      pointer = FFI::MemoryPointer.from_string(string)
      keepalive << pointer
      string_view[:data] = pointer
      string_view[:length] = string.bytesize
    end

    def set_constants(stage_descriptor, constants, keepalive:)
      stage_descriptor[:constant_count] = 0
      stage_descriptor[:constants] = nil
      return if constants.nil? || constants.empty?

      constants_pointer = FFI::MemoryPointer.new(Native::ConstantEntry, constants.size)
      keepalive << constants_pointer

      constants.each_with_index do |(key, value), index|
        entry_pointer = constants_pointer + (index * Native::ConstantEntry.size)
        entry = Native::ConstantEntry.new(entry_pointer)
        entry[:next_in_chain] = nil
        set_nullable_string_view(entry[:key], key.to_s, keepalive:)
        entry[:value] = value.to_f
      end

      stage_descriptor[:constant_count] = constants.size
      stage_descriptor[:constants] = constants_pointer
    end

    def validate_keys!(options, allowed:, required: [], context: "descriptor")
      return options unless options.is_a?(Hash)

      missing = required - options.keys
      raise ArgumentError, "#{context} is missing required keys: #{missing.map(&:inspect).join(", ")}" unless missing.empty?

      unknown = options.keys - allowed
      warn "Unknown #{context} keys: #{unknown.map(&:inspect).join(", ")}" unless unknown.empty?
      options
    end
  end
end
