# frozen_string_literal: true

class Fino::Settings::Select
  class Option
    attr_reader :label, :value, :metadata

    def initialize(label:, value:, metadata: {})
      @label = label
      @value = value
      @metadata = metadata
    end
  end

  class OptionRegistry
    using Fino::Ext::Hash

    UnknownOption = Class.new(Fino::Error)

    def initialize
      @options = {}
      @indexed_options = {}
      @builders = {}
    end

    def register(builder, path)
      @builders.deep_set(builder, *path)
    end

    def options(*path)
      resolve(path)
      @options.dig(*path.compact.map(&:to_s))
    end

    def option(value, *path)
      resolve(path)
      @indexed_options.dig(*path.compact.map(&:to_s)).fetch(value) do
        raise UnknownOption, "Unknown option: #{value} for setting: #{path.compact.join('.')}"
      end
    end

    def refreshable?(*path)
      builder = @builders.dig(*path.compact.map(&:to_s))
      builder.respond_to?(:call)
    end

    def refresh!(*path)
      string_path = path.compact.map(&:to_s)
      builder = @builders.dig(*string_path)

      return unless builder.respond_to?(:call)

      resolve(path, force: true)
      @options.dig(*string_path)
    end

    private

    def resolve(path, force: false)
      string_path = path.compact.map(&:to_s)

      return if !force && @options.dig(*string_path)

      builder = @builders.dig(*string_path)
      options = builder.respond_to?(:call) ? builder.call(refresh: force) : builder

      @options.deep_set(options, *string_path)
      @indexed_options.deep_set(options.index_by(&:value), *string_path)
    end
  end

  include Fino::Setting

  self.type_identifier = :select

  class << self
    def serialize(setting_definition, value)
      Fino.registry.option_registry.option(value.value, *setting_definition.path).value
    end

    def deserialize(setting_definition, raw_value)
      Fino.registry.option_registry.option(raw_value, *setting_definition.path)
    end
  end

  def options
    Fino.registry.option_registry.options(*definition.path)
  end

  def refreshable?
    Fino.registry.option_registry.refreshable?(*definition.path)
  end

  def refresh!
    Fino.registry.option_registry.refresh!(*definition.path)
  end
end
