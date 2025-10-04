# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Settings interaction", type: :integration do
  before do
    Fino.configure do
      adapter { TestHelpers.adapter }
      cache { TestHelpers.cache }

      settings do
        setting :maintenance_mode,
                :boolean,
                default: false,
                description: <<~DESC.strip
                  Enable maintenance mode for the system. Users will see a maintenance page when this is enabled
                DESC

        setting :api_rate_limit,
                :integer,
                default: 1000,
                description: "Maximum API requests per minute per user to prevent abuse"

        section :openai, label: "OpenAI" do
          setting :model,
                  :string,
                  default: "gpt-4o",
                  description: "OpenAI model"

          setting :temperature,
                  :float,
                  default: 0.7,
                  description: "Model temperature"
        end
      end
    end
  end

  describe "global value" do
    context "when setting value was not updated by user yet" do
      it { expect(Fino.value(:api_rate_limit)).to eq(1000) }
    end

    context "when setting value was updated by user" do
      before do
        Fino.set(api_rate_limit: 1500)
      end

      it { expect(Fino.value(:api_rate_limit)).to eq(1500) }
    end
  end

  describe "overrides" do
    context "when no overrides were set" do
      before do
        Fino.set(maintenance_mode: true)
      end

      it { expect(Fino.value(:maintenance_mode)).to eq(true) }
    end

    context "when override is set for the user" do
      before do
        Fino.set(maintenance_mode: false, overrides: { "qa" => true })
      end

      it { expect(Fino.value(:maintenance_mode, for: "qa")).to eq(true) }
      it { expect(Fino.value(:maintenance_mode, for: "admin")).to eq(false) }
    end
  end

  describe "a/b testing" do
    context "when no experiment is set" do
      before do
        Fino.set(api_rate_limit: 1000)
      end

      it { expect(Fino.setting(:api_rate_limit).experiment).to eq(nil) }

      it { expect(Fino.value(:api_rate_limit, for: "user_1")).to eq(1000) }
      it { expect(Fino.value(:api_rate_limit, for: "user_2")).to eq(1000) }
      it { expect(Fino.value(:api_rate_limit, for: "user_3")).to eq(1000) }
      it { expect(Fino.value(:api_rate_limit, for: "user_4")).to eq(1000) }
      it { expect(Fino.value(:api_rate_limit, for: "user_5")).to eq(1000) }
    end

    context "when experiment is set" do
      before do
        Fino.set(
          api_rate_limit: 1000,
          variants: {
            30.0 => 3000,
            20.0 => 4000
          }
        )
      end

      it "stores experiment configuration correctly" do
        setting = Fino.setting(:api_rate_limit)
        experiment = setting.experiment

        expect(experiment).not_to eq(nil)
        expect(experiment.variants.size).to eq(3) # 2 variants + control
        expect(experiment.variants.map(&:percentage).sum).to eq(100.0) # control takes all remaining percentage
      end

      it "correctly stores control variant" do
        control_variant = Fino.setting(:api_rate_limit)
                              .experiment
                              .variants
                              .find { |v| v.value == Fino::AbTesting::Variant::CONTROL_VALUE }

        expect(control_variant.percentage).to eq(50.0)
      end

      it "picks variant for passed scopes and sticks to it" do
        setting = Fino.setting(:api_rate_limit)
        experiment = setting.experiment

        control_variant = experiment.variants.find { |v| v.value == Fino::AbTesting::Variant::CONTROL_VALUE }
        twenty_percent_variant = experiment.variants.find { |v| v.percentage == 20.0 }
        thirty_percent_variant = experiment.variants.find { |v| v.percentage == 30.0 }

        expect(experiment.variant(for: "user_1").id).to eq(twenty_percent_variant.id)
        expect(experiment.variant(for: "user_1").id).to eq(twenty_percent_variant.id)
        expect(setting.value(for: "user_1")).to eq(4000)

        expect(experiment.variant(for: "user_2").id).to eq(control_variant.id)
        expect(experiment.variant(for: "user_2").id).to eq(control_variant.id)
        expect(setting.value(for: "user_2")).to eq(1000)

        expect(experiment.variant(for: "user_3").id).to eq(twenty_percent_variant.id)
        expect(experiment.variant(for: "user_3").id).to eq(twenty_percent_variant.id)
        expect(setting.value(for: "user_3")).to eq(4000)

        expect(experiment.variant(for: "user_4").id).to eq(control_variant.id)
        expect(experiment.variant(for: "user_4").id).to eq(control_variant.id)
        expect(setting.value(for: "user_4")).to eq(1000)

        expect(experiment.variant(for: "user_5").id).to eq(thirty_percent_variant.id)
        expect(experiment.variant(for: "user_5").id).to eq(thirty_percent_variant.id)
        expect(setting.value(for: "user_5")).to eq(3000)
      end
    end
  end
end
