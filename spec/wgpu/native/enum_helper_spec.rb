# frozen_string_literal: true

require_relative "../../../lib/wgpu/native/enum_helper"

RSpec.describe WGPU::Native::EnumHelper, :no_native do
  let(:flags) { { none: 0, read: 1, write: 2, execute: 4, all: 7 } }

  describe ".coerce" do
    it "coerces symbols and preserves integers" do
      expect(described_class.coerce(flags, :write)).to eq(2)
      expect(described_class.coerce(flags, 17)).to eq(17)
    end

    it "raises ArgumentError with valid candidates" do
      expect { described_class.coerce(flags, :wrtie, name: "access") }
        .to raise_error(ArgumentError, /Unknown access :wrtie.*:write/)
    end
  end

  describe ".coerce_flags" do
    it "combines symbol arrays" do
      expect(described_class.coerce_flags(flags, [:read, :execute])).to eq(5)
    end

    it "rejects unsupported input types" do
      expect { described_class.coerce_flags(flags, ["read"]) }
        .to raise_error(ArgumentError, /Array of Symbols/)
    end
  end

  describe ".decompose_flags" do
    it "returns atomic symbols without composite aliases" do
      expect(described_class.decompose_flags(flags, 7)).to eq([:read, :write, :execute])
    end
  end
end
