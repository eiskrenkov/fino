# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Solid adapter integration", type: :integration do
  before(:all) do
    SolidTestHelpers.setup_database(:sqlite3)

    Fino.reconfigure do
      adapter { SolidTestHelpers.solid_adapter }
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

  before do
    TestHelpers.cache.clear
    SolidTestHelpers.clear_database
  end

  it_behaves_like "fino adapter integration"
end
