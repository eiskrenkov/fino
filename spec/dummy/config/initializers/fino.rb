# frozen_string_literal: true

require "fino-redis"

Rails.application.configure do
  config.fino.cache_within_request = false
  config.fino.preload_before_request = true
  config.fino.instrument = true
end

Fino.configure do
  adapter do
    Fino::Redis::Adapter.new(
      Redis.new(host: ENV.fetch("FINO_DUMMY_REDIS_HOST", "redis.fino.orb.local")),
      namespace: "fino_dummy"
    )
  end

  cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }

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

    section :feature_toggles, label: "Feature Toggles" do
      setting :new_ui, :boolean, default: true, description: "Enable the new user interface"
      setting :beta_functionality, :boolean, default: false, description: "Enable beta functionality for testing"
    end

    section :some_external_integration, label: "External integration" do
      setting :integration_enabled,
              :boolean,
              default: false,
              description: "Acts as a circuit breaker for the integration"

      setting :http_read_timeout, :integer, default: 200 # in ms
      setting :http_open_timeout, :integer, default: 100 # in ms

      setting :max_retries, :integer, default: 3, description: "Maximum number of retries for failed requests"
    end
  end
end
