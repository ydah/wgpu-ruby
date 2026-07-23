# frozen_string_literal: true

module WGPU
  class << self
    attr_accessor :debug_leaks
  end

  self.debug_leaks = ENV["WGPU_DEBUG_LEAKS"] == "1"

  module LeakTracker
    @resources = {}
    @mutex = Mutex.new

    module_function

    def register(resource)
      return unless WGPU.debug_leaks

      object_id = resource.object_id
      description = describe(resource)
      @mutex.synchronize { @resources[object_id] = description }
      ObjectSpace.define_finalizer(resource, finalizer(object_id))
    end

    def unregister(resource)
      @mutex.synchronize { @resources.delete(resource.object_id) }
    end

    def warn_remaining
      resources = @mutex.synchronize do
        remaining = @resources.values
        @resources.clear
        remaining
      end
      resources.each { |description| warn "WGPU resource leaked: #{description}" }
    end

    def describe(resource)
      label = resource.label
      label_text = label ? " label=#{label.inspect}" : ""
      "#{resource.class}#{label_text}"
    end
    private_class_method :describe

    def finalizer(object_id)
      proc do
        description = @mutex.synchronize { @resources.delete(object_id) }
        warn "WGPU resource leaked: #{description}" if description
      end
    end
    private_class_method :finalizer
  end

  at_exit { LeakTracker.warn_remaining if WGPU.debug_leaks }

  module CallbackKeepalive
    INITIALIZATION_MUTEX = Mutex.new

    module_function

    def retain(owner, callback)
      mutex, callbacks = storage_for(owner)
      token = Object.new
      mutex.synchronize { callbacks[token] = callback }
      token
    end

    def release(owner, token)
      return unless token

      mutex, callbacks = storage_for(owner)
      mutex.synchronize { callbacks.delete(token) }
    end

    def count(owner)
      mutex, callbacks = storage_for(owner)
      mutex.synchronize { callbacks.length }
    end

    def storage_for(owner)
      INITIALIZATION_MUTEX.synchronize do
        mutex = owner.instance_variable_get(:@wgpu_callback_keepalive_mutex)
        callbacks = owner.instance_variable_get(:@wgpu_callback_keepalive)
        unless mutex && callbacks
          mutex = Mutex.new
          callbacks = {}
          owner.instance_variable_set(:@wgpu_callback_keepalive_mutex, mutex)
          owner.instance_variable_set(:@wgpu_callback_keepalive, callbacks)
        end
        [mutex, callbacks]
      end
    end
    private_class_method :storage_for
  end

  module NativeResource
    GUARDED_METHOD_EXEMPTIONS = [:initialize, :release, :released?, :handle, :label, :inspect].freeze

    module Lifecycle
      def initialize(*args, **kwargs, &block)
        super
        @released = false
        @label = kwargs[:label] if kwargs.key?(:label)
        LeakTracker.register(self)
      end

      def release(...)
        return if released?

        result = super
        @released = true
        LeakTracker.unregister(self)
        result
      end
    end

    def self.included(base)
      guard = Module.new
      base.public_instance_methods(false).each do |method_name|
        next if GUARDED_METHOD_EXEMPTIONS.include?(method_name)

        guard.define_method(method_name) do |*args, **kwargs, &block|
          ensure_not_released!
          super(*args, **kwargs, &block)
        end
      end
      base.prepend(guard)
      base.prepend(Lifecycle)
    end

    attr_reader :label

    def released?
      return true if @released
      return false unless instance_variable_defined?(:@handle)
      return true if @handle.nil?

      @handle.respond_to?(:null?) && @handle.null?
    end

    def inspect
      label_text = @label ? " label=#{@label.inspect}" : ""
      "#<#{self.class}#{label_text} released=#{released?}>"
    end

    private

    def ensure_not_released!
      return unless released?

      label_text = @label ? " (#{@label})" : ""
      raise ResourceError, "#{self.class}#{label_text} has been released"
    end
  end
end
