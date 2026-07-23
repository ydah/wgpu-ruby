# frozen_string_literal: true

RSpec.describe WGPU::CompilationMessage, :skip_gpu_check do
  subject(:message) do
    described_class.new(
      type: :error,
      message: "unexpected token",
      line_num: 4,
      line_pos: 7,
      offset: 42,
      length: 3
    )
  end

  it "exposes typed diagnostic fields and location aliases" do
    expect(message.type).to eq(:error)
    expect(message.line).to eq(4)
    expect(message.column).to eq(7)
    expect(message.offset).to eq(42)
  end

  it "formats a line-and-column diagnostic" do
    expect(message.to_s).to eq("4:7: error: unexpected token")
  end

  it "requires exactly one shader source" do
    shader = WGPU::ShaderModule.allocate

    expect { shader.send(:select_source, nil, nil) }.to raise_error(
      ArgumentError,
      /exactly one of code: or spirv:/
    )
    expect { shader.send(:select_source, "wgsl", "spirv") }.to raise_error(
      ArgumentError,
      /exactly one of code: or spirv:/
    )
    expect(shader.send(:select_source, nil, "\x03\x02\x23\x07")).to be_a(String)
  end

  it "guards the unimplemented v27 compilation-info function" do
    shader = WGPU::ShaderModule.allocate

    expect { shader.get_compilation_info }.to raise_error(
      WGPU::ShaderError,
      /not implemented by wgpu-native v27\.0\.4\.0/
    )
  end
end
