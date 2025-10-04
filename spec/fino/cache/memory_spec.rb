# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fino::Cache::Memory do
  subject { described_class.new(expires_in: ttl) }

  let(:ttl) { 10 } # seconds (sorry dhh)

  describe "#exist?" do
    it { expect(subject.exist?("key")).to eq(false) }

    context "when key was set" do
      before do
        subject.write("key", 1)
      end

      it { expect(subject.exist?("key")).to eq(true) }
    end
  end

  describe "#read" do
    it { expect(subject.read("key")).to eq(nil) }

    context "when key was set" do
      before do
        subject.write("key", 1)
      end

      it { expect(subject.read("key")).to eq(1) }
    end
  end

  describe "#write" do
    it "does the write i guess" do
      expect { subject.write("key", 1) }
        .to change { subject.exist?("key") }
        .from(false)
        .to(true)
    end
  end

  describe "#fetch" do
    it "raises error if block was not provided" do
      expect { subject.fetch("key") }.to raise_error(ArgumentError)
    end

    it "returns result of block execution" do
      expect(subject.fetch("key") { 1 + 1 }).to eq(2)
    end

    it "stores block result" do
      expect { subject.fetch("key") { 1 + 1 } }
        .to change { subject.read("key") }
        .from(nil)
        .to(2)
    end

    it "doesn't evaluate block is there's already value stored" do
      subject.write("key", 1)

      expect { subject.fetch("key") { raise } }.not_to raise_error
    end
  end

  describe "#fetch_multi" do
    before do
      subject.write("key_1", 1)
    end

    it "yields missing keys and stores combined results" do
      expect(subject.read("key_1")).to eq(1)
      expect(subject.read("key_2")).to eq(nil)
      expect(subject.read("key_3")).to eq(nil)

      subject.fetch_multi("key_1", "key_2", "key_3") do |missing_keys|
        expect(missing_keys).to eq(["key_2", "key_3"])
        [["key_2", 2], ["key_3", 3]]
      end

      expect(subject.read("key_1")).to eq(1)
      expect(subject.read("key_2")).to eq(2)
      expect(subject.read("key_3")).to eq(3)
    end

    it "doesn't evaluate block if there are no missing keys" do
      subject.fetch_multi("key_1", "key_2", "key_3") do |_|
        [["key_2", 2], ["key_3", 3]]
      end

      expect { subject.fetch_multi("key_1", "key_2", "key_3") { raise } }
        .not_to raise_error
    end
  end

  describe "#delete" do
    before do
      subject.write("key", 1)
    end

    it "deletes" do
      expect { subject.delete("key") }
        .to change { subject.exist?("key") }
        .from(true)
        .to(false)
    end
  end

  describe "expiration" do
    # there's no timecop midflight :(

    let(:current_timestamp) { Process.clock_gettime(Process::CLOCK_MONOTONIC, :second) }

    it "expires exist" do
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp)

      subject.write("key", 1)
      expect(subject.exist?("key")).to eq(true)

      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp + (ttl * 10))

      expect(subject.exist?("key")).to eq(false)
    end

    it "expires reads" do
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp)

      subject.write("key", 1)
      expect(subject.read("key")).to eq(1)

      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp + (ttl * 10))

      expect(subject.read("key")).to eq(nil)
    end

    it "expires fetches" do
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp)

      subject.fetch("key") { 1 + 1 }

      expect do |block|
        subject.fetch("key", &block)
      end.not_to yield_control

      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp + (ttl * 10))

      expect do |block|
        subject.fetch("key", &block)
      end.to yield_control
    end

    it "expires fetch miltis" do
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp)

      subject.fetch_multi("key_1", "key_2") { |missing_keys| missing_keys.zip([1, 2]) }

      expect do |block|
        subject.fetch_multi("key_1", "key_2", &block)
      end.not_to yield_control

      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :second)
        .and_return(current_timestamp + (ttl * 10))

      subject.fetch_multi("key_1", "key_2") do |missing_keys|
        expect(missing_keys).to eq(["key_1", "key_2"])
        missing_keys.zip([1, 2])
      end
    end

    context "when cache is immortal" do
      let(:ttl) { nil }

      it "expires reads" do
        allow(Process).to receive(:clock_gettime)
          .with(Process::CLOCK_MONOTONIC, :second)
          .and_return(current_timestamp)

        subject.write("key", 1)
        expect(subject.read("key")).to eq(1)

        allow(Process).to receive(:clock_gettime)
          .with(Process::CLOCK_MONOTONIC, :second)
          .and_return(current_timestamp + 100_000)

        expect(subject.read("key")).to eq(1)
      end
    end
  end
end
