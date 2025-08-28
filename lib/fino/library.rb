class Fino::Library
  attr_reader :config

  def initialize(config)
    @config = config
    @memoized_settings = {}
  end

  def read(setting_name, section_name)
    setting(setting_name, section_name).value
  end

  private

  def setting(setting_name, section_name)
    setting_definition = settings_registry.fetch(setting_name, section_name)

    fetch_from_memoized_settings(setting_definition) do
      fetch_from_cache(setting_definition) do
        fetch_from_adapter(setting_definition)
      end
    end
  end

  def fetch_from_memoized_settings(setting_definition, &)
    @memoized_settings.dig(setting_definition.path, &)
  end

  def fetch_from_cache(setting_definition, &)
    config.cache.fetch(setting_definition.path, &)
  end

  def read_multi
    setting_definitions.zip(adapter.read_multi(setting_definitions.map(&:key))).each do |definition, raw_value|
      definition.type_class.new(definition.key, definition.section, raw_value)
    end
  end
end
