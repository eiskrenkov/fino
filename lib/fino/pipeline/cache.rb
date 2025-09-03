class Fino::Pipeline::Cache
  def initialize(cache)
    @cache = cache
  end

  def read(setting_definition, &block)
    cache.fetch(setting_definition.key, &block)
  end

  def read_multi(setting_definitions, &block)
  end

  def write(setting_definition, value)
    cache.write(setting_definition.key, setting_definition.type_class.build(setting_definition, value))
  end

  private

  attr_reader :cache
end
