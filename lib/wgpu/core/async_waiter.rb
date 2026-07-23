# frozen_string_literal: true

module WGPU
  module AsyncWaiter
    POLL_INTERVAL_SECONDS = 0.001
    CALLBACK_MODE_FALLBACK = {
      allow_process_events: 2,
      allow_spontaneous: 3
    }.freeze

    module_function

    def poll_interval
      @poll_interval ||= POLL_INTERVAL_SECONDS
    end

    def poll_interval=(seconds)
      value = Float(seconds)
      raise ArgumentError, "poll interval must be positive" unless value.positive?

      @poll_interval = value
    end

    # Selects the native callback delivery mode for an operation.
    #
    # @param instance [Instance, nil] instance capable of processing events
    # @return [Integer] native {Native::CallbackMode} value
    def callback_mode(instance:)
      if instance
        callback_mode_value(:allow_process_events)
      else
        callback_mode_value(:allow_spontaneous)
      end
    end

    def wait(status_holder:, instance: nil, device: nil, future: nil, timeout: nil)
      timeout = Float(timeout) if timeout
      raise ArgumentError, "timeout must be non-negative" if timeout&.negative?

      deadline = monotonic_time + timeout if timeout
      wait_info = build_wait_info(future) if instance && Native.future_api?

      until status_holder[:done]
        raise_timeout!(timeout) if deadline && monotonic_time >= deadline

        waited = false
        if instance && wait_info
          waited = wait_with_wait_any(instance, wait_info)
        elsif instance
          instance.process_events
        elsif device && Native.device_poll_available?
          Native.wgpuDevicePoll(device.handle, 0, nil)
        end
        sleep(poll_interval) unless status_holder[:done] || waited
      end
    end

    def callback_mode_value(name)
      Native::CallbackMode[name] || CALLBACK_MODE_FALLBACK.fetch(name)
    end
    private_class_method :callback_mode_value

    def build_wait_info(future)
      return nil unless future.respond_to?(:[])

      id = future[:id].to_i
      return nil if id.zero?

      wait_info = Native::FutureWaitInfo.new
      wait_info[:future] = future
      wait_info[:completed] = 0
      wait_info
    rescue StandardError
      nil
    end
    private_class_method :build_wait_info

    def wait_with_wait_any(instance, wait_info)
      status = Native.wgpuInstanceWaitAny(instance.handle, 1, wait_info.to_ptr, 0)
      return false if [:success, :timed_out].include?(status)

      raise Error, "wgpuInstanceWaitAny failed: #{status.inspect}"
    end
    private_class_method :wait_with_wait_any

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
    private_class_method :monotonic_time

    def raise_timeout!(timeout)
      raise TimeoutError, "GPU operation timed out after #{timeout} seconds"
    end
    private_class_method :raise_timeout!
  end
end
