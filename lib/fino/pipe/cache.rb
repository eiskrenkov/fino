# frozen_string_literal: true

class Fino::Pipe::Cache
  include Fino::Pipe

  def initialize(cache)
    @cache = cache
  end

  def read(setting_definition, &)
    cache.fetch(setting_definition.key, &)
  end

  def read_multi(setting_definitions, &); end

  def write(setting_definition, value)
    cache.write(setting_definition.key, setting_definition.type_class.build(setting_definition, value))
  end

  private

  attr_reader :cache
end
