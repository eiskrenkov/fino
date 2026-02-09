# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fino::Setting do
  before do
    Fino.reconfigure do
      adapter { TestHelpers.adapter }
      cache { TestHelpers.cache }

      settings do
        setting :maintenance_mode, :boolean, default: false
        setting :api_rate_limit, :integer, default: 1000

        section :openai, label: "OpenAI" do
          setting :model, :string, default: "gpt-5"
        end
      end
    end
  end

  describe "#add_override" do
    context "when setting has no existing overrides" do
      before do
        Fino.set(api_rate_limit: 1500)
      end

      it "adds the override" do
        Fino.add_override(:api_rate_limit, "qa" => 2000)

        setting = Fino.setting(:api_rate_limit)
        expect(setting.overrides).to eq("qa" => 2000)
        expect(setting.value(for: "qa")).to eq(2000)
      end
    end

    context "when setting already has overrides" do
      before do
        Fino.set(api_rate_limit: 1500, overrides: { "qa" => 2000 })
      end

      it "appends without replacing existing overrides" do
        Fino.add_override(:api_rate_limit, "staging" => 3000)

        setting = Fino.setting(:api_rate_limit)
        expect(setting.overrides).to eq("qa" => 2000, "staging" => 3000)
      end

      it "allows overwriting a specific scope" do
        Fino.add_override(:api_rate_limit, "qa" => 2500)

        setting = Fino.setting(:api_rate_limit)
        expect(setting.overrides).to eq("qa" => 2500)
      end
    end

    context "when preserving global value" do
      before do
        Fino.set(api_rate_limit: 1500)
      end

      it "does not change the global value" do
        Fino.add_override(:api_rate_limit, "qa" => 2000)

        setting = Fino.setting(:api_rate_limit)
        expect(setting.global_value).to eq(1500)
      end
    end

    context "when setting has A/B experiment variants" do
      before do
        Fino.set(
          api_rate_limit: 1000,
          overrides: { "qa" => 1500 },
          variants: { 30.0 => 3000, 20.0 => 4000 }
        )
      end

      it "preserves experiment variants" do
        Fino.add_override(:api_rate_limit, "staging" => 2000)

        setting = Fino.setting(:api_rate_limit)
        expect(setting.experiment).not_to eq(nil)
        expect(setting.experiment.variants.size).to eq(3)
      end

      it "preserves existing overrides" do
        Fino.add_override(:api_rate_limit, "staging" => 2000)

        setting = Fino.setting(:api_rate_limit)
        expect(setting.overrides).to eq("qa" => 1500, "staging" => 2000)
      end
    end

    context "with sectioned settings" do
      before do
        Fino.set(model: "gpt-6", at: :openai)
      end

      it "adds override to a sectioned setting" do
        Fino.add_override(:model, at: :openai, "qa" => "self-hosted-model")

        setting = Fino.setting(:model, at: :openai)
        expect(setting.overrides).to eq("qa" => "self-hosted-model")
        expect(setting.global_value).to eq("gpt-6")
      end
    end

    context "when setting was never persisted" do
      it "uses the default value as global value" do
        Fino.add_override(:api_rate_limit, "qa" => 2000)

        setting = Fino.setting(:api_rate_limit)
        expect(setting.global_value).to eq(1000)
        expect(setting.value(for: "qa")).to eq(2000)
      end
    end
  end
end
