# frozen_string_literal: true

module WGPU
  module Native
    class << self
      # Reports whether future-based callback waiting is available.
      # @return [Boolean]
      def future_api?
        optional_function_available?(:wgpuInstanceWaitAny)
      end

      # Reports whether explicit device polling is available.
      # @return [Boolean]
      def device_poll_available?
        optional_function_available?(:wgpuDevicePoll)
      end

      # wgpu-native v27 exports wgpuShaderModuleGetCompilationInfo, but the
      # implementation is a Rust panic stub. Calling it aborts the process, so
      # symbol presence alone cannot be used as a capability check.
      def compilation_info_available?
        Distribution.capability_implemented?(:compilation_info)
      end

      # Reports whether querying buffer map state is safe in the pinned runtime.
      # @return [Boolean]
      def buffer_map_state_available?
        Distribution.capability_implemented?(:buffer_map_state)
      end

      # Reports whether native asynchronous pipeline creation is implemented.
      # @return [Boolean]
      def pipeline_async_available?
        Distribution.capability_implemented?(:pipeline_async)
      end

      # Reports whether native logging callbacks and levels are available.
      # @return [Boolean]
      def logging_available?
        optional_function_available?(:wgpuSetLogCallback) &&
          optional_function_available?(:wgpuSetLogLevel)
      end
    end
  end
end
