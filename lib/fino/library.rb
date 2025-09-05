# frozen_string_literal: true

require "forwardable"

class Fino::Library
  def initialize(configuration)
    @configuration = configuration
  end

  def value(*setting_path)
    setting(*setting_path).value
  end

  def setting(*setting_path)
    pipeline.read(build_setting_definition(*setting_path))
  end

  def all
    pipeline.read_multi(configuration.registry.setting_definitions)
  end

  def set(value, *setting_path)
    setting_definition = build_setting_definition(*setting_path)

    pipeline.write(
      setting_definition.type_class.deserialize(value),
      setting_definition
    )
  end

  private

  attr_reader :configuration

  def build_setting_definition(*setting_path)
    configuration.registry.fetch(*setting_path)
  end

  def pipeline
    @pipeline ||= Fino::Pipeline.new.tap do |p|
      p.use Fino::Pipeline::Cache.new(cache) if cache
      p.use Fino::Pipeline::Adapter.new(adapter)
    end
  end

  def cache
    return @cache if defined?(@cache)

    @cache = configuration.cache_builder_block&.call
  end

  def adapter
    @adapter ||= configuration.adapter_builder_block.call
  end
end
