# frozen_string_literal: true

class Fino::Pipe::Cache
  include Fino::Pipe

  def initialize(pipe, cache)
    super(pipe)
    @cache = cache
  end

  def read(setting_definition)
    return cache.read(setting_definition.key) if cache.exist?(setting_definition.key)

    pipe.read(setting_definition).tap do |result|
      cache.write(setting_definition.key, result)
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

  attr_reader :cache
end
