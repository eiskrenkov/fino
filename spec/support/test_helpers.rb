# frozen_string_literal: true

module TestHelpers
  module_function

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
    @adapter ||= Fino::Redis::Adapter.new(redis, namespace: "fino_test")
  end
end
