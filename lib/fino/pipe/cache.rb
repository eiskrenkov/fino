# frozen_string_literal: true

class Fino::Pipe::Cache
  include Fino::Pipe

  def initialize(pipe, cache)
    super(pipe)
    @cache = cache
  end

  def read(setting_definition)
    cache.fetch(setting_definition.key) do
      pipe.read(setting_definition)
    end
  end

  def read_multi(setting_definitions)
    cache.fetch_multi(setting_definitions.map(&:key)) do |missing_keys|
      uncached_setting_definitions = setting_definitions.filter { |sd| missing_keys.include?(sd.key) }

      missing_keys.zip(pipe.read_multi(uncached_setting_definitions))
    end
  end

  def write(setting_definition, value)
    pipe.write(setting_definition, value)

    cache.write(
      setting_definition.key,
      setting_definition.type_class.build(setting_definition, value)
    )
  end

  private

  attr_reader :cache
end
