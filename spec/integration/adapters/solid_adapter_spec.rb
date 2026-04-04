# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Solid adapter integration", type: :integration do
  before(:all) do
    skip "Solid adapter not under test" unless TestHelpers.solid_adapter?

    Fino.reconfigure do
      adapter { Fino::Solid::Adapter.new }
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

  describe "#supports_ab_testing_analysis?" do
    it "returns true" do
      expect(Fino::Solid::Adapter.new.supports_ab_testing_analysis?).to eq(true)
    end
  end
end
