# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Redis adapter integration", type: :integration do
  before(:all) do
    skip "Redis adapter not under test" unless TestHelpers.redis_adapter?

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

  describe "A/B testing analysis (Redis-specific)" do
    before do
      Fino.set(api_rate_limit: 1000, variants: { 30.0 => 3000, 20.0 => 4000 })
    end

    describe "#supports_ab_testing_analysis?" do
      it "returns true" do
        expect(TestHelpers.adapter.supports_ab_testing_analysis?).to eq(true)
      end
    end

    describe "#record_ab_testing_conversion" do
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
    end

    describe "#clear_ab_testing_conversions" do
      it "removes the tracking set" do
        Fino.convert!(:api_rate_limit, for: "user_1")

        tracking_key = "fino_test:ck:api_rate_limit"
        expect(TestHelpers.redis.exists?(tracking_key)).to eq(true)

        Fino.reset_analysis!(:api_rate_limit)

        expect(TestHelpers.redis.exists?(tracking_key)).to eq(false)
      end
    end
  end
end
