# frozen_string_literal: true

module WGPU
  class Instance
    attr_reader :handle

    def initialize
      desc = Native::InstanceDescriptor.new
      desc[:next_in_chain] = nil
      desc[:features][:next_in_chain] = nil
      desc[:features][:timed_wait_any_enable] = 1
      desc[:features][:timed_wait_any_max_count] = 1

      @handle = Native.wgpuCreateInstance(desc)
      raise InitializationError, "Failed to create WebGPU instance" if @handle.null?
    end

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

    def enumerate_adapters_async(backends: nil)
      AsyncTask.new do
        enumerate_adapters(backends: backends)
      end
    end

    def get_canvas_context(present_info)
      CanvasContext.new(self, present_info)
    end

    def process_events
      Native.wgpuInstanceProcessEvents(@handle)
    end

    def release
      return if @handle.null?
      Native.wgpuInstanceRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

  end
end
