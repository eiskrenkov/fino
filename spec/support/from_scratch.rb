# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    TestHelpers.cache.clear
    TestHelpers.redis.flushdb
  end
end
