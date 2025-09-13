# frozen_string_literal: true

require "forwardable"

class Fino::Library
  def initialize(configuration)
    @configuration = configuration
  end

  def value(setting_name, at: nil)
    setting(setting_name, at: at).value
  end

  def values(*setting_names, at: nil)
    settings(*setting_names, at: at).map(&:value)
  end

  def setting(setting_name, at: nil)
    pipeline.read(build_setting_definition(setting_name, at: at))
  end

  def settings(*setting_names, at: nil)
    setting_definitions =
      if setting_names.empty? && at.nil?
        configuration.registry.setting_definitions
      else
        setting_names.map { |name| build_setting_definition(name, at: at) }
      end

    pipeline.read_multi(setting_definitions)
  end

  def set(**setting_names_to_values)
    at = setting_names_to_values.delete(:at)

    setting_names_to_values.each do |setting_name, value|
      setting_definition = build_setting_definition(setting_name, at: at)

      pipeline.write(
        setting_definition,
        setting_definition.type_class.deserialize(value)
      )
    end
  end

  def slice(**mapping)
    setting_definitions = mapping.each_with_object([]) do |(section_name, setting_names), memo|
      Array(setting_names).each do |setting_name|
        memo << build_setting_definition(setting_name, at: section_name)
      end
    end

    pipeline.read_multi(setting_definitions)
  end

  private

  attr_reader :configuration

  def build_setting_definition(setting_name, at: nil)
    configuration.registry.fetch(setting_name.to_s, at.to_s)
  end

  def pipeline
    @pipeline ||= Fino::Pipeline.new(storage).tap do |p|
      p.use Fino::Pipe::Cache, cache if cache
      p.instance_exec(&configuration.pipeline_builder_block) if configuration.pipeline_builder_block
    end
  end

  def storage
    Fino::Pipe::Storage.new(configuration.adapter_builder_block.call)
  end

  def cache
    defined?(@cache) ? @cache : @cache = configuration.cache_builder_block&.call
  end
end
