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
        Distribution.capability_implemented?(:compilation_info)
      end

      def buffer_map_state_available?
        Distribution.capability_implemented?(:buffer_map_state)
      end

      def pipeline_async_available?
        Distribution.capability_implemented?(:pipeline_async)
      end

      def logging_available?
        optional_function_available?(:wgpuSetLogCallback) &&
          optional_function_available?(:wgpuSetLogLevel)
      end
    end
  end
end
