# frozen_string_literal: true

require "forwardable"

class Fino::Library
  extend Forwardable

  def_delegators :configuration, :registry, :adapter_instance, :cache_instance

  def initialize(configuration)
    @configuration = configuration
    @memoized_settings = {}
  end

  def value(setting_name, section_name = nil)
    setting(setting_name, section_name).value
  end

  def setting(setting_name, section_name = nil)
    setting_definition = registry.fetch(setting_name, section_name)

    fetch_from_memoized_settings(setting_definition) do
      fetch_from_cache(setting_definition) do
        fetch_from_adapter(setting_definition)
      end
    end
  end

  def sections
  end

  def all
    adapter_instance.all
  end

  private

  attr_reader :configuration

  def fetch_from_memoized_settings(setting_definition)
    @memoized_settings.dig(*setting_definition.path) || yield
  end

  def fetch_from_cache(setting_definition, &)
    cache_instance.fetch(setting_definition.path, &)
  end

  def fetch_from_adapter(setting_definition)
    adapter_instance.setting(setting_definition)
  end

  def read_multi
    # setting_definitions.zip(adapter_instance.read_multi(setting_definitions.map(&:key))).each do |definition, raw_value|
    #   definition.type_class.new(definition.key, definition.section, raw_value)
    # end
  end
end
