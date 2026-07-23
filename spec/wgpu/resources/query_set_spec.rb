# frozen_string_literal: true

RSpec.describe WGPU::QuerySet, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates an occlusion query set" do
      query_set = device.create_query_set(type: :occlusion, count: 4)
      expect(query_set).to be_a(WGPU::QuerySet)
      expect(query_set.handle).not_to be_null
      query_set.release
    end

  end

  describe "#count" do
    it "returns the query count" do
      query_set = device.create_query_set(type: :occlusion, count: 8)
      expect(query_set.count).to eq(8)
      query_set.release
    end
  end

  describe "#type" do
    it "returns the query type" do
      query_set = device.create_query_set(type: :occlusion, count: 2)
      expect(query_set.type).to eq(:occlusion)
      query_set.release
    end
  end

  describe "#destroy" do
    it "destroys and then releases the query set safely" do
      query_set = device.create_query_set(type: :occlusion, count: 2)
      expect { query_set.destroy }.not_to raise_error
      expect { query_set.release }.not_to raise_error
      expect(query_set).to be_released
    end
  end

  describe "#release" do
    it "releases the query set" do
      query_set = device.create_query_set(type: :occlusion, count: 2)
      query_set.release
      expect(query_set.handle).to be_null
    end

    it "can be called multiple times" do
      query_set = device.create_query_set(type: :occlusion, count: 2)
      query_set.release
      expect { query_set.release }.not_to raise_error
    end
  end
end
