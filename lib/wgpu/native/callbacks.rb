# frozen_string_literal: true

module WGPU
  module Native
    callback :request_adapter_callback,
             [RequestAdapterStatus, :pointer, StringView.by_value, :pointer, :pointer], :void

    callback :request_device_callback,
             [RequestDeviceStatus, :pointer, StringView.by_value, :pointer, :pointer], :void

    callback :buffer_map_callback,
             [MapAsyncStatus, StringView.by_value, :pointer, :pointer], :void

    callback :uncaptured_error_callback,
             [:pointer, ErrorType, StringView.by_value, :pointer, :pointer], :void

    callback :device_lost_callback,
             [:pointer, DeviceLostReason, StringView.by_value, :pointer, :pointer], :void

    callback :pop_error_scope_callback,
             [PopErrorScopeStatus, ErrorType, StringView.by_value, :pointer, :pointer], :void

    callback :queue_work_done_callback,
             [QueueWorkDoneStatus, :pointer, :pointer], :void

    callback :log_callback,
             [LogLevel, StringView.by_value, :pointer], :void
  end
end
