# frozen_string_literal: true

class Fino::Rails::RequestScopedCache::Pipe
  include Fino::Pipe

  def self.with_store
    Thread.current[:fino_request_store] = Fino::Rails::RequestScopedCache::Store.new
    yield
  ensure
    Thread.current[:fino_request_store] = nil
  end

  def read(setting_definition, &)
    store.fetch(setting_definition.key, &)
  end

  def read_multi(setting_definitions, &)
  end

  def write(setting_definition, value)
    store.write(
      setting_definition.key,
      setting_definition.type_class.build(setting_definition, value)
    )
  end

  private

  def store
    Thread.current[:fino_request_store] ||
      raise(ArgumentError, "No request store available. Make sure to use Middleware")
  end
end
