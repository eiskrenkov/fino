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

  def enabled?(setting_name, at: nil, **context)
    setting = setting(setting_name, at: at)
    raise ArgumentError, "Setting #{setting_name} is not a boolean" unless setting.instance_of?(Fino::Settings::Boolean)

    setting.enabled?(**context)
  end

  def disabled?(setting_name, at: nil, **context)
    setting = setting(setting_name, at: at)
    raise ArgumentError, "Setting #{setting_name} is not a boolean" unless setting.instance_of?(Fino::Settings::Boolean)

    setting.disabled?(**context)
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

  def set(**data)
    at = data.delete(:at)
    raw_overrides = data.delete(:overrides) || {}
    raw_variants = data.delete(:variants) || {}

    setting_name, raw_value = data.first
    setting_definition = build_setting_definition(setting_name, at: at)
    value = setting_definition.type_class.deserialize(raw_value)

    overrides = raw_overrides.transform_values { |v| setting_definition.type_class.deserialize(v) }

    experiment = Fino::AbTesting::Experiment.new(setting_definition)

    raw_variants.map do |percentage, value|
      experiment << Fino::AbTesting::Variant.new(
        percentage: percentage,
        value: setting_definition.type_class.deserialize(value)
      )
    end

    pipeline.write(
      setting_definition,
      value,
      overrides,
      experiment.variants
    )
  end

  def slice(*settings)
    setting_definitions = settings.each_with_object([]) do |symbol_or_hash, memo|
      case symbol_or_hash
      when Symbol
        memo << build_setting_definition(symbol_or_hash)
      when Hash
        symbol_or_hash.each do |section_name, setting_names|
          Array(setting_names).each do |setting_name|
            memo << build_setting_definition(setting_name, at: section_name)
          end
        end
      else
        raise ArgumentError, "Settings to preload should be either symbols or hashes"
      end
    end

    pipeline.read_multi(setting_definitions)
  end

  def persisted_keys
    adapter.read_persisted_setting_keys
  end

  private

  attr_reader :configuration

  def build_setting_definition(setting_name, at: nil)
    configuration.registry.setting_definition!(setting_name.to_s, at&.to_s)
  end

  def pipeline
    @pipeline ||= Fino::Pipeline.new(storage).tap do |p|
      p.use Fino::Pipe::Cache, cache if cache
      p.instance_exec(&configuration.pipeline_builder_block) if configuration.pipeline_builder_block
    end
  end

  def storage
    Fino::Pipe::Storage.new(adapter)
  end

  def adapter
    @adapter ||= configuration.adapter_builder_block.call
  end

  def cache
    defined?(@cache) ? @cache : @cache = configuration.cache_builder_block&.call
  end
end
