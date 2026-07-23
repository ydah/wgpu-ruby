# frozen_string_literal: true

require "timeout"

module WGPU
  class AsyncTask
    # Starts a background task that evaluates the given block.
    # @raise [ArgumentError] if no block is supplied
    def initialize(&block)
      raise ArgumentError, "block is required" unless block

      @value = nil
      @error = nil
      @thread = Thread.new do
        begin
          @value = block.call
        rescue StandardError => e
          @error = e
        end
      end
    end

    # Waits until the task finishes.
    # @param timeout [Numeric, nil] maximum number of seconds to wait
    # @return [AsyncTask] this task
    # @raise [Timeout::Error] if the task does not finish in time
    def wait(timeout: nil)
      joined = timeout ? @thread.join(timeout) : @thread.join
      raise Timeout::Error, "async task timeout" unless joined
      self
    end

    # Waits for and returns the task result.
    # @param timeout [Numeric, nil] maximum number of seconds to wait
    # @return [Object] block result
    # @raise [StandardError] re-raises an exception raised by the block
    def value(timeout: nil)
      wait(timeout: timeout)
      raise @error if @error

      @value
    end

    # Creates a task that transforms this task's result.
    # @yieldparam value [Object] completed task result
    # @return [AsyncTask] chained task
    def then(&block)
      AsyncTask.new do
        block.call(value)
      end
    end

    # Reports whether the task has finished.
    # @return [Boolean]
    def complete?
      !@thread.alive?
    end

    # Reports whether the task is still running.
    # @return [Boolean]
    def pending?
      @thread.alive?
    end

    # Returns the exception raised by the task, if any.
    # @return [StandardError, nil]
    def error
      value
      nil
    rescue StandardError => e
      e
    end
  end
end
