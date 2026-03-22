# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fino::Settings::Select do
  describe Fino::Settings::Select::OptionRegistry do
    subject(:registry) { described_class.new }

    let(:red) { Fino::Settings::Select::Option.new(label: "Red", value: "red") }
    let(:blue) { Fino::Settings::Select::Option.new(label: "Blue", value: "blue") }
    let(:green) { Fino::Settings::Select::Option.new(label: "Green", value: "green") }
    let(:static_options) { [red, blue] }

    describe "#options" do
      context "with static builder" do
        before { registry.register(static_options, %w[storefront color]) }

        it "returns registered options" do
          expect(registry.options("storefront", "color")).to eq([red, blue])
        end
      end

      context "with callable builder" do
        before do
          registry.register(
            proc { |refresh:| [red, blue] },
            %w[dynamic color]
          )
        end

        it "resolves options lazily on first access" do
          expect(registry.options("dynamic", "color")).to eq([red, blue])
        end
      end

      context "with callable builder that is not yet resolved" do
        it "does not call builder until options are accessed" do
          called = false
          builder = proc { |refresh:| called = true; static_options }

          registry.register(builder, %w[lazy setting])

          expect(called).to eq(false)

          registry.options("lazy", "setting")

          expect(called).to eq(true)
        end
      end
    end

    describe "#option" do
      before { registry.register(static_options, %w[storefront color]) }

      it "returns option by value" do
        expect(registry.option("red", "storefront", "color")).to eq(red)
      end

      it "raises UnknownOption for unknown value" do
        expect { registry.option("yellow", "storefront", "color") }.to raise_error(
          Fino::Settings::Select::OptionRegistry::UnknownOption,
          "Unknown option: yellow for setting: storefront.color"
        )
      end
    end

    describe "#refreshable?" do
      it "returns true for callable builder" do
        registry.register(proc { |refresh:| static_options }, %w[dynamic setting])

        expect(registry.refreshable?("dynamic", "setting")).to eq(true)
      end

      it "returns false for static builder" do
        registry.register(static_options, %w[static setting])

        expect(registry.refreshable?("static", "setting")).to eq(false)
      end
    end

    describe "#refresh!" do
      it "calls builder with refresh: true and updates options" do
        builder = proc { |refresh:|
          refresh ? [red, blue, green] : [red, blue]
        }
        registry.register(builder, %w[dynamic setting])

        registry.options("dynamic", "setting")
        expect(registry.options("dynamic", "setting")).to eq([red, blue])

        registry.refresh!("dynamic", "setting")
        expect(registry.options("dynamic", "setting")).to eq([red, blue, green])
      end

      it "returns updated options" do
        builder = proc { |refresh:| refresh ? [red, green] : [red] }
        registry.register(builder, %w[dynamic setting])
        registry.options("dynamic", "setting")

        result = registry.refresh!("dynamic", "setting")

        expect(result).to eq([red, green])
      end

      it "returns nil for static builder" do
        registry.register(static_options, %w[static setting])

        expect(registry.refresh!("static", "setting")).to eq(nil)
      end

      it "makes new options available via #option" do
        builder = proc { |refresh:|
          refresh ? [red, blue, green] : [red, blue]
        }
        registry.register(builder, %w[dynamic setting])
        registry.options("dynamic", "setting")

        expect { registry.option("green", "dynamic", "setting") }.to raise_error(
          Fino::Settings::Select::OptionRegistry::UnknownOption
        )

        registry.refresh!("dynamic", "setting")

        expect(registry.option("green", "dynamic", "setting")).to eq(green)
      end
    end
  end

  describe "setting behavior" do
    before do
      Fino.reconfigure do
        adapter { TestHelpers.adapter }
        cache { TestHelpers.cache }

        settings do
          section :storefront do
            setting :color,
                    :select,
                    options: [
                      Fino::Settings::Select::Option.new(label: "Red", value: "red"),
                      Fino::Settings::Select::Option.new(label: "Blue", value: "blue")
                    ],
                    default: "red"
          end

          section :dynamic do
            setting :provider,
                    :select,
                    options: proc { |refresh:|
                      base = [
                        Fino::Settings::Select::Option.new(label: "A", value: "a"),
                        Fino::Settings::Select::Option.new(label: "B", value: "b")
                      ]
                      base << Fino::Settings::Select::Option.new(label: "C", value: "c") if refresh
                      base
                    },
                    default: "a"
          end
        end
      end
    end

    describe "#options" do
      it "returns options for the setting" do
        setting = Fino.setting(:color, at: :storefront)

        expect(setting.options.map(&:value)).to eq(%w[red blue])
      end
    end

    describe "#refreshable?" do
      it "returns false for static options" do
        expect(Fino.setting(:color, at: :storefront).refreshable?).to eq(false)
      end

      it "returns true for dynamic options" do
        expect(Fino.setting(:provider, at: :dynamic).refreshable?).to eq(true)
      end
    end

    describe "#refresh!" do
      it "updates options via builder" do
        setting = Fino.setting(:provider, at: :dynamic)
        setting.options

        setting.refresh!

        expect(setting.options.map(&:value)).to eq(%w[a b c])
      end
    end

    describe "serialization" do
      it "serializes Option to its value" do
        option = Fino.setting(:color, at: :storefront).options.first

        Fino.set(color: option.value, at: :storefront)

        expect(Fino.setting(:color, at: :storefront).value.value).to eq("red")
      end
    end

    describe "deserialization" do
      it "deserializes raw value to Option" do
        Fino.set(color: "blue", at: :storefront)

        result = Fino.setting(:color, at: :storefront).value

        expect(result).to be_a(Fino::Settings::Select::Option)
        expect(result.value).to eq("blue")
        expect(result.label).to eq("Blue")
      end
    end
  end
end
