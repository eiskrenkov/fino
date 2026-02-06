# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fino::Settings::Boolean do
  before do
    Fino.reconfigure do
      adapter { TestHelpers.adapter }
      cache { TestHelpers.cache }

      settings do
        setting :maintenance_mode, :boolean, default: false
        setting :feature_enabled, :boolean, default: true
      end
    end
  end

  describe "#enabled?" do
    context "when value is true" do
      before do
        Fino.set(maintenance_mode: true)
      end

      it { expect(Fino.setting(:maintenance_mode).enabled?).to eq(true) }
    end

    context "when value is false" do
      before do
        Fino.set(maintenance_mode: false)
      end

      it { expect(Fino.setting(:maintenance_mode).enabled?).to eq(false) }
    end

    context "with default value" do
      it { expect(Fino.setting(:maintenance_mode).enabled?).to eq(false) }
      it { expect(Fino.setting(:feature_enabled).enabled?).to eq(true) }
    end
  end

  describe "#disabled?" do
    context "when value is true" do
      before do
        Fino.set(maintenance_mode: true)
      end

      it { expect(Fino.setting(:maintenance_mode).disabled?).to eq(false) }
    end

    context "when value is false" do
      before do
        Fino.set(maintenance_mode: false)
      end

      it { expect(Fino.setting(:maintenance_mode).disabled?).to eq(true) }
    end

    context "with default value" do
      it { expect(Fino.setting(:maintenance_mode).disabled?).to eq(true) }
      it { expect(Fino.setting(:feature_enabled).disabled?).to eq(false) }
    end
  end
end
