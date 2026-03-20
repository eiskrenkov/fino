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

  include Fino::Setting

  self.type_identifier = :select

  class << self
    def serialize(setting_definition, value)
      Fino.registry.option(value.value, *setting_definition.path).value
    end

    def deserialize(setting_definition, raw_value)
      Fino.registry.option(raw_value, *setting_definition.path)
    end
  end

  def options
    Fino.registry.options(*definition.path)
  end
end
