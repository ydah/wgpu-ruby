# frozen_string_literal: true

module WGPU
  module Native
    class << self
      def future_api?
        respond_to?(:wgpuInstanceWaitAny)
      end

      def device_poll_available?
        respond_to?(:wgpuDevicePoll)
      end
    end
  end
end
