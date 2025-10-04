# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Configuration", type: :integration do
  before do
    Fino.reconfigure do
      adapter { TestHelpers.adapter }
      cache { TestHelpers.cache }

      settings do
        setting :maintenance_mode,
                :boolean,
                default: false,
                description: <<~DESC.strip
                  Enable maintenance mode for the system. Users will see a maintenance page when this is enabled
                DESC

        section :openai, label: "OpenAI" do
          setting :model,
                  :string,
                  default: "gpt-5",
                  description: "OpenAI model"

          setting :temperature,
                  :float,
                  default: 0.7,
                  description: "Model temperature"
        end
      end
    end
  end

  after do
    Fino.reset!
  end

  describe "setting definitions" do
    it "defines basic setting correctly" do
      setting = Fino.setting(:maintenance_mode)

      expect(setting.name)
        .to eq(:maintenance_mode)
      expect(setting.type)
        .to eq(Fino::Settings::Boolean.type_identifier)
      expect(setting.default)
        .to eq(false)
      expect(setting.description)
        .to eq("Enable maintenance mode for the system. Users will see a maintenance page when this is enabled")
    end

    it "defines sectioned settings correctly" do
      Fino.setting(:model, at: :openai).tap do |setting|
        expect(setting.name).to eq(:model)
        expect(setting.type).to eq(Fino::Settings::String.type_identifier)
        expect(setting.default).to eq("gpt-5")
        expect(setting.description).to eq("OpenAI model")
      end

      Fino.setting(:temperature, at: :openai).tap do |setting|
        expect(setting.name).to eq(:temperature)
        expect(setting.type).to eq(Fino::Settings::Float.type_identifier)
        expect(setting.default).to eq(0.7)
        expect(setting.description).to eq("Model temperature")
      end
    end

    it "stores section attributes" do
      setting = Fino.setting(:model, at: :openai)

      expect(setting.section_definition.name).to eq(:openai)
      expect(setting.section_definition.label).to eq("OpenAI")
    end

    context "when trying to register duplicate setting" do
      context "when on top level" do
        it "raises an error" do
          expect do
            Fino.configure do
              settings do
                setting :maintenance_mode, :string
              end
            end
          end.to raise_error(Fino::Registry::DuplicateSetting)
        end
      end

      context "when inside of a section" do
        it "raises an error" do
          expect do
            Fino.configure do
              settings do
                section :openai do
                  setting :model, :string
                end
              end
            end
          end.to raise_error(Fino::Registry::DuplicateSetting)
        end
      end
    end
  end
end
