# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fino::Pipe::Cache do
  subject(:cached_pipe) { described_class.new(pipe, cache) }

  let(:pipe) { instance_double(Fino::Pipe::Storage) }
  let(:cache) { Fino::Cache::Memory.new(expires_in: ttl) }
  let(:ttl) { 10 }
  let(:setting_definition) { instance_double(Fino::Definition::Setting, key: "delay") }
  let(:setting) { instance_double(Fino::Setting) }

  describe "#read" do
    it "reads the setting from the underlying pipe once and caches it" do
      expect(pipe).to receive(:read).with(setting_definition).once.and_return(setting)

      expect(cached_pipe.read(setting_definition)).to eq(setting)
      expect(cached_pipe.read(setting_definition)).to eq(setting)
    end

    it "returns the setting when the cache TTL expires in the middle of the read" do
      current_timestamp = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)

      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp)

      allow(pipe).to receive(:read).with(setting_definition).and_return(setting)

      cached_pipe.read(setting_definition)

      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp, current_timestamp + (ttl * 10))

      expect(cached_pipe.read(setting_definition)).to eq(setting)
    end
  end
end
