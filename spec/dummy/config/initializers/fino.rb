# frozen_string_literal: true

require "fino-redis"
require "fino-solid"

Rails.application.configure do
  config.fino.instrument = Rails.env.development?
  config.fino.log = Rails.env.development?
  config.fino.cache_within_request = false
  config.fino.preload_before_request = true
  config.fino.instrument = true
end

$redis = Redis.new(host: ENV.fetch("FINO_DUMMY_REDIS_HOST", "redis.fino.orb.local"))

Fino.configure do
  case ENV["FINO_DUMMY_ADAPTER"]
  when "redis"
    adapter do
      Fino::Redis::Adapter.new($redis, namespace: "fino_dummy")
    end
  else
    adapter do
      Fino::Solid::Adapter.new
    end
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
              default: "gpt-5",
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

      setting :http_read_timeout, :integer, default: 200, unit: :ms
      setting :http_open_timeout, :integer, default: 100, unit: :ms

      setting :max_retries, :integer, default: 3, description: "Maximum number of retries for failed requests"
    end
  end
end
