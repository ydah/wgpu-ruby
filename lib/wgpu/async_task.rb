# frozen_string_literal: true

require "timeout"

module WGPU
  class AsyncTask
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

    def wait(timeout: nil)
      joined = timeout ? @thread.join(timeout) : @thread.join
      raise Timeout::Error, "async task timeout" unless joined
      self
    end

    def value(timeout: nil)
      wait(timeout: timeout)
      raise @error if @error

      @value
    end

    def then(&block)
      AsyncTask.new do
        block.call(value)
      end
    end

    def complete?
      !@thread.alive?
    end

    def pending?
      @thread.alive?
    end

    def error
      value
      nil
    rescue StandardError => e
      e
    end
  end
end
