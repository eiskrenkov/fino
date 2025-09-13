# frozen_string_literal: true

require "fino-redis"

Rails.application.configure do
  config.fino.preload_before_request = true
end

Fino.configure do
  adapter do
    Fino::Redis::Adapter.new(
      Redis.new(host: "redis.fino.orb.local"),
      namespace: "fino_dummy"
    )
  end

  cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }

  settings do
    setting :maintenance_mode, :boolean, default: false
    setting :test, :boolean, default: false

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
      setting :new_ui, :boolean, default: true
      setting :beta_functionality, :boolean, default: false
    end

    section :my_micro_service, label: "My Micro Service" do
      setting :http_read_timeout, :integer, default: 200 # in ms
      setting :http_open_timeout, :integer, default: 100 # in ms
    end
  end
end
