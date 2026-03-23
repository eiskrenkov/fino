# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Redis adapter integration", type: :integration do
  before(:all) do
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

        setting :api_rate_limit,
                :integer,
                default: 1000,
                description: "Maximum API requests per minute per user to prevent abuse"

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

  it_behaves_like "fino adapter integration"

  describe "A/B testing analysis" do
    before do
      Fino.set(api_rate_limit: 1000, variants: { 30.0 => 3000, 20.0 => 4000 })
    end

    describe "#supports_ab_testing_analysis?" do
      it "returns true" do
        expect(TestHelpers.adapter.supports_ab_testing_analysis?).to eq(true)
      end
    end

    describe "#record_ab_testing_conversion" do
      it "records a conversion" do
        Fino.convert!(:api_rate_limit, for: "user_1")

        analysis = Fino.analyse(:api_rate_limit)

        expect(analysis.total_conversions).to eq(1)
      end

      it "records only the first conversion per scope (NX semantics)" do
        Fino.convert!(:api_rate_limit, for: "user_1", time: Time.new(2026, 3, 1))
        Fino.convert!(:api_rate_limit, for: "user_1", time: Time.new(2026, 3, 20))

        analysis = Fino.analyse(:api_rate_limit)

        expect(analysis.total_conversions).to eq(1)
      end

      it "records conversions for different scopes" do
        Fino.convert!(:api_rate_limit, for: "user_1")
        Fino.convert!(:api_rate_limit, for: "user_2")
        Fino.convert!(:api_rate_limit, for: "user_5")

        analysis = Fino.analyse(:api_rate_limit)

        expect(analysis.total_conversions).to eq(3)
      end

      it "tracks conversion keys in a set for later cleanup" do
        Fino.convert!(:api_rate_limit, for: "user_1")

        tracking_key = "fino_test:ck:api_rate_limit"
        tracked_keys = TestHelpers.redis.smembers(tracking_key)

        expect(tracked_keys).not_to be_empty
        expect(tracked_keys).to all(start_with("fino_test:c:api_rate_limit:"))
      end

      it "sets TTL on conversion sorted sets" do
        Fino.convert!(:api_rate_limit, for: "user_1")

        setting = Fino.setting(:api_rate_limit)
        variant = setting.experiment.variant(for: "user_1")
        conversion_key = "fino_test:c:api_rate_limit:#{variant.id}"

        ttl = TestHelpers.redis.ttl(conversion_key)

        expect(ttl).to be > 0
        expect(ttl).to be <= 7 * 24 * 60 * 60
      end

      it "accepts custom time" do
        custom_time = Time.new(2026, 3, 15, 12, 0, 0)
        Fino.convert!(:api_rate_limit, for: "user_1", time: custom_time)

        analysis = Fino.analyse(:api_rate_limit)
        variant_with_conversion = analysis.variants_data.find { |vd| vd.conversions_count > 0 }

        expect(variant_with_conversion.daily_conversions).to eq("2026-03-15" => 1)
      end
    end

    describe "#read_ab_testing_conversions" do
      it "returns per-variant conversion data" do
        Fino.convert!(:api_rate_limit, for: "user_1")
        Fino.convert!(:api_rate_limit, for: "user_2")
        Fino.convert!(:api_rate_limit, for: "user_5")

        analysis = Fino.analyse(:api_rate_limit)

        expect(analysis.variants_data.size).to eq(3)
        expect(analysis.variants_data.map(&:conversions_count).sum).to eq(3)
      end

      it "aggregates daily conversions correctly" do
        Fino.convert!(:api_rate_limit, for: "user_day1", time: Time.new(2026, 3, 10))
        Fino.convert!(:api_rate_limit, for: "user_day2", time: Time.new(2026, 3, 10))
        Fino.convert!(:api_rate_limit, for: "user_day3", time: Time.new(2026, 3, 11))

        analysis = Fino.analyse(:api_rate_limit)
        all_daily = analysis.variants_data.each_with_object({}) do |vd, memo|
          vd.daily_conversions.each { |date, count| memo[date] = (memo[date] || 0) + count }
        end

        expect(all_daily["2026-03-10"]).to eq(2)
        expect(all_daily["2026-03-11"]).to eq(1)
      end

      it "returns empty data when no conversions exist" do
        analysis = Fino.analyse(:api_rate_limit)

        expect(analysis.any_conversions?).to eq(false)
        expect(analysis.total_conversions).to eq(0)
        analysis.variants_data.each do |vd|
          expect(vd.conversions_count).to eq(0)
          expect(vd.daily_conversions).to be_empty
        end
      end
    end

    describe "#clear_ab_testing_conversions" do
      it "removes all conversion data" do
        Fino.convert!(:api_rate_limit, for: "user_1")
        Fino.convert!(:api_rate_limit, for: "user_5")

        expect(Fino.analyse(:api_rate_limit).total_conversions).to eq(2)

        Fino.reset_analysis!(:api_rate_limit)

        expect(Fino.analyse(:api_rate_limit).total_conversions).to eq(0)
      end

      it "removes the tracking set" do
        Fino.convert!(:api_rate_limit, for: "user_1")

        tracking_key = "fino_test:ck:api_rate_limit"
        expect(TestHelpers.redis.exists?(tracking_key)).to eq(true)

        Fino.reset_analysis!(:api_rate_limit)

        expect(TestHelpers.redis.exists?(tracking_key)).to eq(false)
      end

      it "does not affect the setting value" do
        Fino.convert!(:api_rate_limit, for: "user_1")
        Fino.reset_analysis!(:api_rate_limit)

        expect(Fino.value(:api_rate_limit)).to eq(1000)
        expect(Fino.setting(:api_rate_limit).experiment).not_to be_nil
      end
    end
  end
end
