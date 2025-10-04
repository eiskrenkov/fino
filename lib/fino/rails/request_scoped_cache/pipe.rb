# frozen_string_literal: true

class Fino::Rails::RequestScopedCache::Pipe
  include Fino::Pipe

  def self.with_temporary_cache
    Thread.current[:fino_request_scoped_cache] = Fino::Cache::Memory.new(expires_in: nil)
    yield
  ensure
    Thread.current[:fino_request_scoped_cache] = nil
  end

  def read(setting_definition)
    cache.fetch(setting_definition.key) do
      pipe.read(setting_definition)
    end
  end

  def read_multi(setting_definitions)
    cache.fetch_multi(*setting_definitions.map(&:key)) do |missing_keys|
      uncached_setting_definitions = setting_definitions.filter { |sd| missing_keys.include?(sd.key) }

      missing_keys.zip(pipe.read_multi(uncached_setting_definitions))
    end
  end

  def write(setting_definition, value, overrides, variants)
    pipe.write(setting_definition, value, overrides, variants)

    cache.delete(setting_definition.key)
  end

  private

  def cache
    Thread.current[:fino_request_scoped_cache] ||
      raise(ArgumentError, "No request store available. Make sure to use Middleware")
  end
end
