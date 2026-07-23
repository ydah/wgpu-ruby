# frozen_string_literal: true

require_relative "../../examples/rendering_example_helper"

RSpec.describe ExampleRendering do
  class RenderingExampleFakeWindow
    attr_reader :drawable_size_calls

    def initialize(*drawable_sizes)
      @drawable_sizes = drawable_sizes
      @last_drawable_size = drawable_sizes.last
      @drawable_size_calls = 0
    end

    def drawable_size
      @drawable_size_calls += 1
      @last_drawable_size = @drawable_sizes.shift || @last_drawable_size
    end
  end

  class RenderingExampleFakeSurface
    attr_reader :configurations, :current_texture_calls

    def initialize(*acquisition_results)
      @acquisition_results = acquisition_results
      @configurations = []
      @current_texture_calls = 0
    end

    def configure(**configuration)
      @configurations << configuration
    end

    def current_texture
      @current_texture_calls += 1
      result = @acquisition_results.shift
      raise result if result.is_a?(Exception)

      result
    end
  end

  def build_setup(window:, surface:, width: 800, height: 600)
    described_class::Setup.new(
      window: window,
      surface: surface,
      device: :device,
      format: :bgra8_unorm,
      width: width,
      height: height,
      present_mode: :fifo
    )
  end

  describe ".resize_if_needed" do
    it "does not reconfigure an unchanged drawable" do
      window = RenderingExampleFakeWindow.new([800, 600])
      surface = RenderingExampleFakeSurface.new
      setup = build_setup(window: window, surface: surface)

      expect(described_class.resize_if_needed(setup)).to be(false)
      expect(surface.configurations).to be_empty
    end

    it "reconfigures a changed drawable and reports the new size" do
      window = RenderingExampleFakeWindow.new([1024, 768])
      surface = RenderingExampleFakeSurface.new
      setup = build_setup(window: window, surface: surface)
      resized_to = nil

      result = described_class.resize_if_needed(setup) do |width, height|
        resized_to = [width, height]
      end

      expect(result).to be(true)
      expect(resized_to).to eq([1024, 768])
      expect([setup.width, setup.height]).to eq([1024, 768])
      expect(surface.configurations).to contain_exactly(
        device: :device,
        format: :bgra8_unorm,
        width: 1024,
        height: 768,
        present_mode: :fifo
      )
    end

    it "can force reconfiguration at the current size" do
      window = RenderingExampleFakeWindow.new([800, 600])
      surface = RenderingExampleFakeSurface.new
      setup = build_setup(window: window, surface: surface)

      expect(described_class.resize_if_needed(setup, force: true)).to be(true)
      expect(surface.configurations).to contain_exactly(
        device: :device,
        format: :bgra8_unorm,
        width: 800,
        height: 600,
        present_mode: :fifo
      )
    end

    it "does not configure a zero-sized drawable" do
      window = RenderingExampleFakeWindow.new([0, 0])
      surface = RenderingExampleFakeSurface.new
      setup = build_setup(window: window, surface: surface)

      expect(described_class.resize_if_needed(setup, force: true)).to be(false)
      expect(surface.configurations).to be_empty
    end
  end

  describe ".acquire_surface_texture" do
    it "returns the acquired texture" do
      window = RenderingExampleFakeWindow.new([800, 600])
      surface = RenderingExampleFakeSurface.new(:texture)
      setup = build_setup(window: window, surface: surface)

      expect(described_class.acquire_surface_texture(setup)).to eq(:texture)
      expect(surface.current_texture_calls).to eq(1)
    end

    it "returns nil when acquisition times out" do
      timeout = WGPU::SurfaceAcquisitionError.new(:timeout)
      window = RenderingExampleFakeWindow.new([800, 600])
      surface = RenderingExampleFakeSurface.new(timeout)
      setup = build_setup(window: window, surface: surface)

      expect(described_class.acquire_surface_texture(setup)).to be_nil
      expect(surface.current_texture_calls).to eq(1)
      expect(surface.configurations).to be_empty
    end

    it "returns nil without acquiring when the drawable is minimized" do
      window = RenderingExampleFakeWindow.new([0, 0])
      surface = RenderingExampleFakeSurface.new(:texture)
      setup = build_setup(window: window, surface: surface)

      expect(described_class.acquire_surface_texture(setup)).to be_nil
      expect(window.drawable_size_calls).to eq(1)
      expect(surface.current_texture_calls).to eq(0)
      expect(surface.configurations).to be_empty
    end

    [
      [:outdated, [1024, 768]],
      [:lost, [800, 600]]
    ].each do |status, recovered_size|
      it "force-reconfigures and retries once after #{status}" do
        acquisition_error = WGPU::SurfaceAcquisitionError.new(status)
        window = RenderingExampleFakeWindow.new([800, 600], recovered_size)
        surface = RenderingExampleFakeSurface.new(acquisition_error, :texture)
        setup = build_setup(window: window, surface: surface)
        resized_to = nil

        texture = described_class.acquire_surface_texture(setup) do |width, height|
          resized_to = [width, height]
        end

        expect(texture).to eq(:texture)
        expect(resized_to).to eq(recovered_size)
        expect(window.drawable_size_calls).to eq(2)
        expect(surface.current_texture_calls).to eq(2)
        expect(surface.configurations).to contain_exactly(
          device: :device,
          format: :bgra8_unorm,
          width: recovered_size.fetch(0),
          height: recovered_size.fetch(1),
          present_mode: :fifo
        )
      end
    end

    it "propagates a second recoverable acquisition failure" do
      first_error = WGPU::SurfaceAcquisitionError.new(:outdated)
      second_error = WGPU::SurfaceAcquisitionError.new(:lost)
      window = RenderingExampleFakeWindow.new([800, 600], [800, 600])
      surface = RenderingExampleFakeSurface.new(first_error, second_error)
      setup = build_setup(window: window, surface: surface)

      expect do
        described_class.acquire_surface_texture(setup)
      end.to raise_error(second_error)
      expect(surface.current_texture_calls).to eq(2)
      expect(surface.configurations.size).to eq(1)
    end

    it "propagates a recoverable error when the drawable is minimized" do
      outdated = WGPU::SurfaceAcquisitionError.new(:outdated)
      window = RenderingExampleFakeWindow.new([800, 600], [0, 0])
      surface = RenderingExampleFakeSurface.new(outdated)
      setup = build_setup(window: window, surface: surface)

      expect do
        described_class.acquire_surface_texture(setup)
      end.to raise_error(outdated)
      expect(surface.current_texture_calls).to eq(1)
      expect(surface.configurations).to be_empty
    end

    [:out_of_memory, :device_lost, :error, :unknown].each do |status|
      it "propagates the fatal #{status} status" do
        fatal_error = WGPU::SurfaceAcquisitionError.new(status)
        window = RenderingExampleFakeWindow.new([800, 600])
        surface = RenderingExampleFakeSurface.new(fatal_error)
        setup = build_setup(window: window, surface: surface)

        expect do
          described_class.acquire_surface_texture(setup)
        end.to raise_error(fatal_error)
        expect(surface.current_texture_calls).to eq(1)
        expect(surface.configurations).to be_empty
      end
    end
  end
end
