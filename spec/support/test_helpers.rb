# frozen_string_literal: true

module TestHelpers
  VALID_ADAPTERS = %w[redis solid/sqlite3 solid/postgresql solid/mysql2 solid/trilogy].freeze
  DEFAULT_ADAPTER = "redis"

  module_function

  def adapter_env
    @adapter_env ||= ENV.fetch("FINO_TEST_ADAPTER", DEFAULT_ADAPTER).tap do |value|
      unless VALID_ADAPTERS.include?(value)
        raise "Unknown test adapter: #{value}. Valid: #{VALID_ADAPTERS.join(', ')}"
      end
    end
  end

  def redis_adapter?
    adapter_env == "redis"
  end

  def solid_adapter?
    adapter_env.start_with?("solid/")
  end

  def cache
    @cache ||= Fino::Cache::Memory.new(expires_in: 10)
  end

  def redis
    @redis ||= Redis.new(
      host: ENV.fetch("FINO_TEST_REDIS_HOST", "redis.fino.orb.local"),
      db: ENV.fetch("FINO_TEST_REDIS_DB", "15").to_i
    )
  end

  def adapter
    @adapter ||= if redis_adapter?
                   Fino::Redis::Adapter.new(redis, namespace: "fino_test")
                 elsif solid_adapter?
                   Fino::Solid::Adapter.new
                 end
  end
end
