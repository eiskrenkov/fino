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

    describe "after_write callback" do
      it "is called with correct arguments after writing a setting" do
        callback_args = nil

        Fino.reconfigure do
          adapter { TestHelpers.adapter }
          cache { TestHelpers.cache }

          after_write do |setting_definition, value, overrides, variants|
            callback_args = [setting_definition, value, overrides, variants]
          end

          settings do
            setting :maintenance_mode, :boolean, default: false
          end
        end

        Fino.set(maintenance_mode: true, overrides: { admin: true })

        expect(callback_args).not_to be_nil
        expect(callback_args[0].key).to eq("maintenance_mode")
        expect(callback_args[1]).to eq(true)
        expect(callback_args[2]).to eq(admin: true)
        expect(callback_args[3]).to eq([])
      end

      context "when callback filters by tags" do
        let(:callback_log) { [] }

        before do
          log = callback_log

          Fino.reconfigure do
            adapter { TestHelpers.adapter }
            cache { TestHelpers.cache }

            after_write do |setting_definition, value, _overrides, _variants|
              next unless setting_definition.tags.include?(:audited)

              log << { key: setting_definition.key, value: value }
            end

            settings do
              setting :tracked_flag, :boolean, default: false, tags: [:audited]
              setting :untracked_flag, :boolean, default: false
            end
          end
        end

        it "runs callback for settings with matching tag" do
          Fino.set(tracked_flag: true)

          expect(callback_log).to eq([{ key: "tracked_flag", value: true }])
        end

        it "skips callback for settings without matching tag" do
          Fino.set(untracked_flag: true)

          expect(callback_log).to be_empty
        end
      end
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
