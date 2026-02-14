# frozen_string_literal: true

require "forwardable"

# The core engine that handles all settings operations.
#
# Fino::Library reads and writes settings through a composable pipeline,
# backed by a storage adapter and optional cache. It is the target of all
# delegated methods on the Fino module.
#
# You typically interact with Library indirectly via +Fino.value+,
# +Fino.set+, etc. Direct instantiation is only needed for advanced use
# cases.
#
# == Reading settings
#
#   Fino.value(:model, at: :openai)
#   Fino.values(:model, :temperature, at: :openai)
#   Fino.setting(:model, at: :openai).overrides
#
# == Writing settings
#
#   Fino.set(model: "gpt-6", at: :openai)
#   Fino.set(model: "gpt-5", at: :openai, overrides: { "qa" => "local" })
#   Fino.set(model: "gpt-5", at: :openai, variants: { 20.0 => "gpt-6" })
#
# == Preloading
#
#   Fino.slice(:api_rate_limit, openai: [:model, :temperature])
class Fino::Library
  include FeatureTogglesSupport

  def initialize(configuration)
    @configuration = configuration
  end

  # Returns the resolved value of a single setting.
  #
  # Supports scoped overrides and A/B variant resolution via the +for:+ context key.
  # Numeric settings additionally accept a +unit:+ key for unit conversion.
  #
  #   Fino.value(:model, at: :openai)                  #=> "gpt-5"
  #   Fino.value(:model, at: :openai, for: "qa")       #=> "local_model"
  #   Fino.value(:timeout, at: :svc, unit: :sec)       #=> 0.2
  #
  # +setting_name+ - Symbol name of the setting.
  # +at+ - Optional Symbol section name.
  # +context+ - Optional keyword arguments passed to Setting#value
  #             (+for:+ scope, +unit:+ conversion target).
  #
  # Returns the deserialized setting value.
  def value(setting_name, at: nil, **context)
    setting(setting_name, at: at).value(**context)
  end

  # Returns an Array of resolved values for the given settings.
  #
  #   Fino.values(:model, :temperature, at: :openai) #=> ["gpt-5", 0.7]
  #
  # +setting_names+ - One or more Symbol setting names.
  # +at+ - Optional Symbol section name applied to all settings.
  # +context+ - Optional keyword arguments forwarded to each Setting#value.
  #
  # Returns an Array of deserialized values.
  def values(*setting_names, at: nil, **context)
    settings(*setting_names, at: at).map { |s| s.value(**context) }
  end

  # Returns a single Fino::Setting object for the given setting.
  #
  # The Setting object exposes +value+, +overrides+, +experiment+,
  # +default+, +description+, and other metadata.
  #
  #   setting = Fino.setting(:model, at: :openai)
  #   setting.value           #=> "gpt-5"
  #   setting.overrides       #=> { "qa" => "local_model" }
  #   setting.ab_tested?      #=> true
  #
  # +setting_name+ - Symbol name of the setting.
  # +at+ - Optional Symbol section name.
  #
  # Returns a Fino::Setting instance.
  def setting(setting_name, at: nil)
    pipeline.read(build_setting_definition(setting_name, at: at))
  end

  # Returns an Array of Fino::Setting objects.
  #
  # When called with no arguments and no +at+, returns all registered settings.
  # When +at+ is provided without names, returns all settings in that section.
  # When names are provided, returns only the requested settings.
  #
  #   Fino.settings                                     #=> all settings
  #   Fino.settings(at: :openai)                        #=> settings in openai section
  #   Fino.settings(:model, :temperature, at: :openai)  #=> specific settings
  #
  # +setting_names+ - Zero or more Symbol setting names.
  # +at+ - Optional Symbol section name.
  #
  # Returns an Array of Fino::Setting instances.
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

  # Adds scope overrides to an existing setting, merging with any overrides
  # already present.
  #
  #   Fino.add_override(:model, at: :openai, "admin" => "gpt-2000")
  #
  # +setting_name+ - Symbol name of the setting.
  # +at+ - Optional Symbol section name.
  # +overrides+ - Keyword arguments mapping scope strings to raw values.
  #
  # Returns +true+.
  def add_override(setting_name, at: nil, **overrides)
    setting_definition = build_setting_definition(setting_name, at: at)
    current_setting = pipeline.read(setting_definition)

    deserialized_overrides = overrides.transform_values { |v| setting_definition.type_class.deserialize(v) }
    merged_overrides = current_setting.overrides.merge(deserialized_overrides)

    variants = current_setting.experiment&.variants || []

    pipeline.write(
      setting_definition,
      current_setting.global_value,
      merged_overrides,
      variants
    )

    true
  end

  # Persists a setting value with optional scoped overrides and A/B testing variants.
  #
  # Accepts exactly one +setting_name: value+ pair as keyword arguments, plus
  # optional +at:+, +overrides:+, and +variants:+ keys.
  #
  #   Fino.set(model: "gpt-6", at: :openai)
  #   Fino.set(model: "gpt-5", at: :openai, overrides: { "qa" => "local" })
  #   Fino.set(model: "gpt-5", at: :openai, variants: { 20.0 => "gpt-6" })
  #
  # +data+ - Keyword arguments containing:
  #          * one +name: value+ pair for the setting
  #          * +at:+ - optional Symbol section name
  #          * +overrides:+ - optional Hash mapping scope strings to raw values
  #          * +variants:+ - optional Hash mapping Float percentages to raw variant values
  #
  # Returns +true+.
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

    true
  end

  # Preloads a specific subset of settings in a single adapter call.
  #
  # Accepts a mix of Symbol names (for top-level settings) and Hash entries
  # (for sectioned settings).
  #
  #   Fino.slice(:api_rate_limit, openai: [:model, :temperature])
  #
  # +settings+ - Symbols or Hashes describing which settings to preload.
  #
  # Returns an Array of Fino::Setting instances.
  #
  # Raises +ArgumentError+ if an element is neither Symbol nor Hash.
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

  # Returns an Array of setting keys that have been persisted to the adapter.
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
