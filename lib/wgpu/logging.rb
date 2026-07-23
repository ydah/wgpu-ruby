# frozen_string_literal: true

module WGPU
  class << self
    # Returns the configured wgpu-native log level.
    attr_reader :log_level

    # Sets the wgpu-native log level.
    #
    # @param level [Symbol, Integer] one of `:off`, `:error`, `:warn`, `:info`,
    #   `:debug`, or `:trace`
    # @return [Symbol, Integer] the supplied level
    def log_level=(level)
      ensure_native_logging!
      value = Native::EnumHelper.coerce(Native::LogLevel, level, name: "log level")
      Native.wgpuSetLogLevel(value)
      @log_level = Native::LogLevel[value]
    end

    # Registers a process-wide wgpu-native log handler.
    #
    # The native callback is retained by the WGPU module for the rest of the
    # process, or until this method replaces it.
    #
    # @yieldparam level [Symbol] native log severity
    # @yieldparam message [String] UTF-8 log message
    # @return [WGPU]
    def on_log(&handler)
      raise ArgumentError, "block is required" unless handler

      ensure_native_logging!
      @log_handler = handler
      @native_log_callback = FFI::Function.new(
        :void,
        [:uint32, Native::StringView.by_value, :pointer]
      ) do |level, message, _userdata|
        text =
          if message[:data] && !message[:data].null? && message[:length].positive?
            message[:data].read_string(message[:length])
          else
            ""
          end
        @log_handler.call(Native::LogLevel[level] || level, text)
      rescue StandardError => e
        warn "WGPU log handler failed: #{e.class}: #{e.message}"
      end
      Native.wgpuSetLogCallback(@native_log_callback, nil)
      self
    end

    private

    def ensure_native_logging!
      return if Native.logging_available?

      raise Error,
        "wgpu-native logging is unavailable in the loaded library " \
        "(expected #{Native::Distribution::VERSION})"
    end
  end

  @log_level = :warn
end
