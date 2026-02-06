# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fino::Settings::Numeric do
  describe Fino::Settings::Numeric::Unit do
    describe ".for" do
      it "returns Milliseconds for 'ms'" do
        expect(described_class.for("ms")).to be_a(described_class::Milliseconds)
      end

      it "returns Milliseconds for 'milliseconds'" do
        expect(described_class.for("milliseconds")).to be_a(described_class::Milliseconds)
      end

      it "returns Seconds for 'sec'" do
        expect(described_class.for("sec")).to be_a(described_class::Seconds)
      end

      it "returns Seconds for 'seconds'" do
        expect(described_class.for("seconds")).to be_a(described_class::Seconds)
      end

      it "returns Generic for unknown identifiers" do
        unit = described_class.for("requests")
        expect(unit).to be_a(described_class::Generic)
        expect(unit.name).to eq("Requests")
      end
    end
  end

  describe "#value" do
    before do
      Fino.reconfigure do
        adapter { TestHelpers.adapter }
        cache { TestHelpers.cache }

        settings do
          section :integration do
            setting :http_read_timeout, :integer, default: 200, unit: :ms
            setting :http_open_timeout, :integer, default: 1, unit: :sec
            setting :max_retries, :integer, default: 3
          end

          section :rates do
            setting :refresh_interval, :float, default: 0.5, unit: :sec
          end
        end
      end
    end

    describe "unit conversion" do
      context "when converting milliseconds to seconds" do
        it "converts correctly" do
          setting = Fino.setting(:http_read_timeout, at: :integration)
          expect(setting.value(unit: :seconds)).to eq(0.2)
        end

        it "converts correctly with updated value" do
          Fino.set(http_read_timeout: 500, at: :integration)
          setting = Fino.setting(:http_read_timeout, at: :integration)
          expect(setting.value(unit: :sec)).to eq(0.5)
        end
      end

      context "when converting seconds to milliseconds" do
        it "converts correctly" do
          setting = Fino.setting(:http_open_timeout, at: :integration)
          expect(setting.value(unit: :ms)).to eq(1000)
        end
      end

      context "when converting to the same unit" do
        it "returns the same value" do
          setting = Fino.setting(:http_read_timeout, at: :integration)
          expect(setting.value(unit: :ms)).to eq(setting.global_value)
        end
      end

      context "when no unit option is provided" do
        it "returns the raw value" do
          setting = Fino.setting(:http_read_timeout, at: :integration)
          expect(setting.value).to eq(setting.global_value)
        end
      end

      context "with float settings" do
        it "converts correctly" do
          setting = Fino.setting(:refresh_interval, at: :rates)
          expect(setting.value(unit: :ms)).to eq(500.0)
        end
      end
    end

    describe "error handling" do
      context "when setting has no unit defined" do
        it "raises ArgumentError" do
          setting = Fino.setting(:max_retries, at: :integration)
          expect { setting.value(unit: :seconds) }.to raise_error(
            ArgumentError,
            "No unit defined for this setting"
          )
        end
      end

      context "when units are not convertible" do
        before do
          Fino.reconfigure do
            adapter { TestHelpers.adapter }
            cache { TestHelpers.cache }

            settings do
              setting :request_count, :integer, default: 100, unit: :requests
            end
          end
        end

        it "raises ArgumentError" do
          setting = Fino.setting(:request_count)
          expect { setting.value(unit: :seconds) }.to raise_error(
            ArgumentError,
            "Cannot convert Requests to Seconds"
          )
        end
      end
    end
  end

  describe "#unit" do
    before do
      Fino.reconfigure do
        adapter { TestHelpers.adapter }
        cache { TestHelpers.cache }

        settings do
          setting :with_unit, :integer, default: 100, unit: :ms
          setting :without_unit, :integer, default: 100
        end
      end
    end

    context "when unit is defined" do
      it "returns unit object" do
        setting = Fino.setting(:with_unit)
        expect(setting.unit).to be_a(Fino::Settings::Numeric::Unit::Milliseconds)
      end
    end

    context "when unit is not defined" do
      it "returns nil" do
        setting = Fino.setting(:without_unit)
        expect(setting.unit).to eq(nil)
      end
    end
  end
end
