# frozen_string_literal: true

module WGPU
  class Instance
    attr_reader :handle

    # Creates a WebGPU instance.
    # @raise [InitializationError] if native instance creation fails
    def initialize
      desc = Native::InstanceDescriptor.new
      desc[:next_in_chain] = nil
      desc[:features][:next_in_chain] = nil
      desc[:features][:timed_wait_any_enable] = 0
      desc[:features][:timed_wait_any_max_count] = 0

      @handle = Native.wgpuCreateInstance(desc)
      raise InitializationError, "Failed to create WebGPU instance" if @handle.null?
    end

    # Requests an adapter matching the supplied preferences.
    # @return [Adapter]
    def request_adapter(power_preference: :high_performance, backend: nil, feature_level: :core,
                        force_fallback_adapter: false, compatible_surface: nil, timeout: nil)
      Adapter.request(
        self,
        power_preference: power_preference,
        backend: backend,
        feature_level: feature_level,
        force_fallback_adapter: force_fallback_adapter,
        compatible_surface: compatible_surface,
        timeout: timeout
      )
    end

    # Requests an adapter on a background task.
    # @return [AsyncTask] task yielding an {Adapter}
    def request_adapter_async(power_preference: :high_performance, backend: nil, feature_level: :core,
                              force_fallback_adapter: false, compatible_surface: nil, timeout: nil)
      AsyncTask.new do
        request_adapter(
          power_preference: power_preference,
          backend: backend,
          feature_level: feature_level,
          force_fallback_adapter: force_fallback_adapter,
          compatible_surface: compatible_surface,
          timeout: timeout
        )
      end
    end

    # Lists adapters exposed by the instance.
    # @param backends [Integer, nil] backend bit mask
    # @return [Array<Adapter>]
    def enumerate_adapters(backends: nil)
      options = nil
      if backends
        options = Native::InstanceEnumerateAdapterOptions.new
        options[:next_in_chain] = nil
        options[:backends] = backends
      end

      count = Native.wgpuInstanceEnumerateAdapters(@handle, options, nil)
      return [] if count == 0

      adapters_ptr = FFI::MemoryPointer.new(:pointer, count)
      Native.wgpuInstanceEnumerateAdapters(@handle, options, adapters_ptr)

      adapters_ptr.read_array_of_pointer(count).map do |ptr|
        Adapter.from_handle(ptr, instance: self)
      end
    end

    # Enumerates adapters on a background task.
    # @return [AsyncTask] task yielding adapter objects
    def enumerate_adapters_async(backends: nil)
      AsyncTask.new do
        enumerate_adapters(backends: backends)
      end
    end

    # Creates a canvas context from platform presentation information.
    # @param present_info [Hash] platform surface information
    # @return [CanvasContext]
    def get_canvas_context(present_info)
      CanvasContext.new(self, present_info)
    end

    # Processes pending instance callbacks and events.
    # @return [void]
    def process_events
      Native.wgpuInstanceProcessEvents(@handle)
    end

    # Releases the native instance handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuInstanceRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

  end
end
