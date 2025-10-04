# frozen_string_literal: true

module Fino::Setting
  include Fino::PrettyInspectable

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def type_identitfier=(identifier)
      @type_identitfier = identifier
    end

    def type_identitfier
      @type_identitfier
    end

    def serialize(value)
      raise NotImplementedError
    end

    def deserialize(raw_value)
      raise NotImplementedError
    end
  end

  attr_reader :definition, :global_value, :overrides, :experiment

  def initialize(definition, global_value, overrides = {}, experiment = nil)
    @definition = definition
    @global_value = global_value
    @overrides = overrides
    @experiment = experiment
  end

  def value(**context)
    return global_value unless (scope = context[:for])

    overrides.fetch(scope.to_s) do
      return global_value unless experiment

      value = experiment.value(for: scope)
      return global_value if value == Fino::AbTesting::Variant::CONTROL_VALUE

      value
    end
  end

  def name
    definition.setting_name
  end

  def key
    definition.key
  end

  def type
    definition.type
  end

  def type_class
    definition.type_class
  end

  def section_definition
    definition.section_definition
  end

  def section_name
    definition.section_definition&.name
  end

  def default
    definition.default
  end

  def description
    definition.description
  end

  private

  def inspectable_attributes
    {
      key: key,
      type: type_class,
      default: default,
      global_value: global_value
    }.tap do |attributes|
      attributes[:overrides] = overrides if overrides.present?
      attributes[:experiment] = experiment if experiment
    end
  end
end
