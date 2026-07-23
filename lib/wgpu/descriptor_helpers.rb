# frozen_string_literal: true

module WGPU
  module DescriptorHelpers
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
