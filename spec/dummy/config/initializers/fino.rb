# frozen_string_literal: true

require "fino-redis"

Fino.configure do
  adapter do
    Fino::Redis::Adapter.new(
      Redis.new(host: "redis.fino.orb.local"),
      namespace: "fino_dummy"
    )
  end

  cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }

  settings do
    setting :support_email,
            :string,
            default: "support@fino.com",
            description: "Support email address"

    setting :retries, :integer, default: 3
    setting :debug_mode, :boolean, default: false

    section :http, label: "HTTP timeouts" do
      setting :read_timeout, :float, default: 5.0
      setting :open_timeout, :float, default: 2.0
    end
  end
end
