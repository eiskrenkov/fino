# frozen_string_literal: true

RSpec.shared_examples "fino adapter integration" do
  describe "#value" do
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

    describe "A/B testing" do
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
          expect(experiment.variants.size).to eq(3)
          expect(experiment.variants.map(&:percentage).sum).to eq(100.0)
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

    describe "overrides & A/B testing" do
      before do
        Fino.set(
          api_rate_limit: 1000,
          overrides: {
            "user_3" => 1500
          },
          variants: {
            30.0 => 3000,
            20.0 => 4000
          }
        )
      end

      it "prioritises override" do
        expect(Fino.value(:api_rate_limit)).to eq(1000)

        expect(Fino.value(:api_rate_limit, for: "user_3")).to eq(1500)

        expect(Fino.value(:api_rate_limit, for: "user_1")).to eq(4000)
        expect(Fino.value(:api_rate_limit, for: "user_2")).to eq(1000)

        expect(Fino.value(:api_rate_limit, for: "user_4")).to eq(1000)
        expect(Fino.value(:api_rate_limit, for: "user_5")).to eq(3000)
      end
    end
  end

  describe "#values" do
    describe "general" do
      context "when setting values were not updated by user yet" do
        it "returns defaults" do
          api_rate_limit, maintenance_mode = Fino.values(:api_rate_limit, :maintenance_mode)

          expect(api_rate_limit).to eq(1000)
          expect(maintenance_mode).to eq(false)
        end
      end

      context "when setting value was updated by user" do
        before do
          Fino.set(api_rate_limit: 1500)
          Fino.set(maintenance_mode: true)
        end

        it "returns updated values" do
          api_rate_limit, maintenance_mode = Fino.values(:api_rate_limit, :maintenance_mode)

          expect(api_rate_limit).to eq(1500)
          expect(maintenance_mode).to eq(true)
        end
      end
    end

    describe "sectioned" do
      context "when setting value was updated by user" do
        before do
          Fino.set(model: "gpt-6", at: :openai)
          Fino.set(temperature: 1.0, at: :openai)
        end

        it "returns updated values" do
          model, temperature = Fino.values(:model, :temperature, at: :openai)

          expect(model).to eq("gpt-6")
          expect(temperature).to eq(1.0)
        end
      end
    end
  end

  describe "#setting" do
    before do
      Fino.set(
        model: "gpt-6",
        at: :openai,
        overrides: {
          "qa" => "self-hosted-model"
        },
        variants: {
          30.0 => "gpt-7",
          20.0 => "gpt-7o"
        }
      )
    end

    it "returns an object which allows access to public attributes" do
      setting = Fino.setting(:model, at: :openai)

      expect(setting).to be_a(Fino::Setting)

      expect(setting.name).to eq(:model)
      expect(setting.key).to eq("openai/model")
      expect(setting.type).to eq(Fino::Settings::String.type_identifier)
      expect(setting.type_class).to eq(Fino::Settings::String)

      expect(setting.default).to eq("gpt-5")

      expect(setting.value).to eq("gpt-6")

      expect(setting.experiment).not_to eq(nil)
      expect(setting.experiment.variants.size).to eq(3)
      expect(setting.value(for: "qa")).to eq("self-hosted-model")
      expect(setting.value(for: "user_1")).to eq("gpt-7o")
    end
  end

  describe "#settings" do
    context "when just one setting name is specified" do
      it "returns correct settings" do
        settings = Fino.settings(:model, at: :openai)
        expect(settings.size).to eq(1)

        model_setting = settings.first
        expect(model_setting.key).to eq("openai/model")
      end
    end

    context "when multiple setting names are specified" do
      context "top level" do
        it "returns correct settings" do
          api_rate_limit_setting, maintenance_mode_setting = Fino.settings(:api_rate_limit, :maintenance_mode)

          expect(api_rate_limit_setting.key).to eq("api_rate_limit")
          expect(maintenance_mode_setting.key).to eq("maintenance_mode")
        end
      end

      context "sectioned" do
        it "returns correct settings" do
          model_setting, temperature_setting = Fino.settings(:model, :temperature, at: :openai)

          expect(model_setting.key).to eq("openai/model")
          expect(temperature_setting.key).to eq("openai/temperature")
        end
      end
    end

    context "when just section name is specified" do
      it "returns correct settings" do
        model_setting, temperature_setting = Fino.settings(at: :openai)

        expect(model_setting.key).to eq("openai/model")
        expect(temperature_setting.key).to eq("openai/temperature")
      end
    end

    context "when nothing is specified" do
      it "returns all defined settings" do
        settings = Fino.settings

        expect(settings.map(&:key)).to eq(
          [
            "maintenance_mode",
            "api_rate_limit",
            "openai/model",
            "openai/temperature"
          ]
        )
      end
    end
  end

  describe "#slice" do
    it "slices correctly" do
      api_rate_limit, openai_model = Fino.slice(:api_rate_limit, openai: [:model])

      expect(api_rate_limit.key).to eq("api_rate_limit")
      expect(api_rate_limit.value).to eq(1000)

      expect(openai_model.key).to eq("openai/model")
      expect(openai_model.value).to eq("gpt-5")
    end
  end
end
