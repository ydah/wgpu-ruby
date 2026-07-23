# frozen_string_literal: true

require_relative "../../examples/headless_rendering"

RSpec.describe "headless rendering", :gpu do
  it "renders a red triangle over a blue clear color" do
    result = HeadlessRendering.run

    expect(result[:center]).to all(be_between(0, 255))
    expect(result[:center]).to match([be_within(1).of(255), be_within(1).of(0), be_within(1).of(0), be_within(1).of(255)])
    expect(result[:corner]).to match([be_within(1).of(0), be_within(1).of(0), be_within(1).of(255), be_within(1).of(255)])
  end
end
