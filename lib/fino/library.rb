# frozen_string_literal: true

require "forwardable"

class Fino::Library
  def initialize(configuration)
    @configuration = configuration
  end

  def value(setting_name, at: nil, **context)
    setting(setting_name, at: at).value(**context)
  end

  def values(*setting_names, at: nil, **context)
    settings(*setting_names, at: at).map { |s| s.value(**context) }
  end

  def setting(setting_name, at: nil)
    pipeline.read(build_setting_definition(setting_name, at: at))
  end

  def settings(*setting_names, at: Fino::EMPTINESS)
    setting_definitions =
      if setting_names.empty? && at.equal?(Fino::EMPTINESS)
        configuration.registry.setting_definitions
      elsif at.equal?(Fino::EMPTINESS)
        setting_names.map { |name| build_setting_definition(name) }
      elsif setting_names.empty?
        configuration.registry.setting_definitions(at: at)
      else
        setting_names.map { |name| build_setting_definition(name, at: at) }
      end

    pipeline.read_multi(setting_definitions)
  end

  def variant(setting_name, at: nil, for:)
    setting(setting_name, at: at).variant(
      for: binding.local_variable_get(:for)
    )
  end

  def set(**data)
    at = data.delete(:at)
    raw_overrides = data.delete(:overrides) || {}
    raw_variants = data.delete(:variants) || {}

    setting_name, raw_value = data.first
    setting_definition = build_setting_definition(setting_name, at: at)
    value = setting_definition.type_class.deserialize(raw_value)

    variants = raw_variants.map do |percentage, value|
      Fino::Variant.new(percentage, setting_definition.type_class.deserialize(value))
    end

    variants.prepend(
      Fino::Variant.new(100.0 - variants.sum(&:percentage), Fino::Variant::CONTROL)
    )

    pipeline.write(
      setting_definition,
      value,
      raw_overrides.transform_values { |v| setting_definition.type_class.deserialize(v) },
      variants
    )
  end

  def slice(**mapping)
    setting_definitions = mapping.each_with_object([]) do |(section_name, setting_names), memo|
      Array(setting_names).each do |setting_name|
        memo << build_setting_definition(setting_name, at: section_name)
      end
    end

    pipeline.read_multi(setting_definitions)
  end

  def set_variants(setting_name, at: nil, variants:)
    setting_definition = build_setting_definition(setting_name, at: at)
    pipeline.write_variants(setting_definition, variants)
  end

  private

  attr_reader :configuration

  def build_setting_definition(setting_name, at: nil)
    configuration.registry.setting_definition(setting_name.to_s, at&.to_s)
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
