# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    next unless TestHelpers.solid_adapter?

    db_adapter = TestHelpers.adapter_env.delete_prefix("solid/").to_sym
    SolidTestHelpers.setup_database(db_adapter)
  end

  config.before do
    TestHelpers.cache.clear

    if TestHelpers.solid_adapter?
      SolidTestHelpers.clear_database
    else
      TestHelpers.redis.flushdb
    end
  end
end
