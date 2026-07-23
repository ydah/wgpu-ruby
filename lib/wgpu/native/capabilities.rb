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
    end
  end
end
