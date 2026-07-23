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

    # Registers a live native resource when leak debugging is enabled.
    #
    # @param resource [NativeResource] resource to track
    # @return [void]
    def register(resource)
      return unless WGPU.debug_leaks

      object_id = resource.object_id
      description = describe(resource)
      @mutex.synchronize { @resources[object_id] = description }
      ObjectSpace.define_finalizer(resource, finalizer(object_id))
    end

    # Removes a resource from leak tracking.
    #
    # @param resource [NativeResource] resource that was released
    # @return [void]
    def unregister(resource)
      @mutex.synchronize { @resources.delete(resource.object_id) }
    end

    # Warns about and clears every tracked resource.
    #
    # @return [void]
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
    RETAINED_MUTEX = Mutex.new
    RETAINED_CALLBACKS = {}

    module_function

    # Retains an FFI callback for as long as an operation needs it.
    #
    # @param owner [Object] object that owns the callback registry
    # @param callback [FFI::Function] callback to retain
    # @return [Object] opaque token used by {.release}
    def retain(owner, callback)
      mutex, callbacks = storage_for(owner)
      token = Object.new
      mutex.synchronize { callbacks[token] = callback }
      RETAINED_MUTEX.synchronize { RETAINED_CALLBACKS[token] = callback }
      token
    end

    # Releases a retained callback token.
    #
    # @param owner [Object] object that owns the callback registry
    # @param token [Object, nil] token returned by {.retain}
    # @return [void]
    def release(owner, token)
      return unless token

      mutex, callbacks = storage_for(owner)
      mutex.synchronize { callbacks.delete(token) }
      RETAINED_MUTEX.synchronize { RETAINED_CALLBACKS.delete(token) }
    end

    # Returns the number of callbacks retained for an owner.
    #
    # @param owner [Object] object that owns the callback registry
    # @return [Integer] retained callback count
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

    module ClassMethods
      private

      def adopt_native_handle(handle, label: nil)
        resource = allocate
        resource.send(:initialize_native_resource, handle: handle, label: label)
      end
    end

    module Lifecycle
      UNSET = Object.new.freeze
      private_constant :UNSET

      # Initializes a wrapper and registers its native-resource lifecycle.
      #
      # @param args [Array] positional arguments forwarded to the resource
      # @param kwargs [Hash] keyword arguments forwarded to the resource
      # @yield block forwarded to the resource initializer
      # @return [NativeResource] initialized resource
      def initialize(*args, **kwargs, &block)
        super
        initialize_native_resource(label: kwargs.fetch(:label, UNSET))
      end

      # Releases a resource once and unregisters it from leak tracking.
      #
      # @return [void]
      def release(...)
        return if released?

        result = super
        @released = true
        LeakTracker.unregister(self)
        result
      end

      private

      def initialize_native_resource(handle: UNSET, label: UNSET)
        @handle = handle unless handle.equal?(UNSET)
        @label = label unless label.equal?(UNSET)
        @released = false
        LeakTracker.register(self)
        self
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
      base.extend(ClassMethods)
      base.prepend(guard)
      base.prepend(Lifecycle)
    end

    attr_reader :label

    # Reports whether the native handle has been released or is null.
    # @return [Boolean]
    def released?
      return true if @released
      return false unless instance_variable_defined?(:@handle)
      return true if @handle.nil?

      @handle.respond_to?(:null?) && @handle.null?
    end

    # Yields this wrapper and always releases it when the block exits.
    #
    # This is Ruby convenience API; WebGPU itself has no block-scoped resource
    # primitive.
    #
    # @yieldparam resource [NativeResource] this resource
    # @return the block result
    def use
      raise ArgumentError, "block is required" unless block_given?

      ensure_not_released!
      yield self
    ensure
      release if block_given? && !released?
    end

    # Returns a concise lifecycle-oriented representation.
    #
    # @return [String] class, optional label, and release state
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
