# frozen_string_literal: true

module WGPU
  module Native
    class << self
      def future_api?
        optional_function_available?(:wgpuInstanceWaitAny)
      end

      def device_poll_available?
        optional_function_available?(:wgpuDevicePoll)
      end

      # wgpu-native v27 exports wgpuShaderModuleGetCompilationInfo, but the
      # implementation is a Rust panic stub. Calling it aborts the process, so
      # symbol presence alone cannot be used as a capability check.
      def compilation_info_available?
        Distribution::VERSION != "v27.0.4.0"
      end

      def buffer_map_state_available?
        Distribution::VERSION != "v27.0.4.0"
      end

      def logging_available?
        optional_function_available?(:wgpuSetLogCallback) &&
          optional_function_available?(:wgpuSetLogLevel)
      end
    end
  end
end
