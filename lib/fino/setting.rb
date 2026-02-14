# frozen_string_literal: true

# Base module included by all setting type classes (String, Integer, Float, Boolean).
#
# Provides the common interface for setting instances: value resolution with
# scope overrides and A/B testing, plus metadata accessors delegated to the
# underlying Fino::Definition::Setting.
#
# == Value Resolution Order
#
# When +value(for: scope)+ is called:
# 1. Check scoped overrides for a match
# 2. Check A/B testing experiment for a variant assignment
# 3. Fall back to the global value
#
# == Class Methods (via ClassMethods)
#
# Each type class must implement +serialize+ and +deserialize+ for converting
# between Ruby objects and storage-friendly string representations.
module Fino::Setting
  include Fino::PrettyInspectable

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class-level methods extended onto setting type classes.
  module ClassMethods
    # Sets the Symbol identifier for this type (e.g. +:string+, +:integer+).
    def type_identifier=(identifier)
      @type_identifier = identifier
    end

    # Returns the Symbol type identifier for this setting type.
    def type_identifier
      @type_identifier
    end

    # Converts a Ruby value to a string for storage.
    #
    # Must be implemented by each type class.
    def serialize(value)
      raise NotImplementedError
    end

    # Converts a raw storage value back to the appropriate Ruby type.
    #
    # Must be implemented by each type class.
    def deserialize(raw_value)
      raise NotImplementedError
    end
  end

  # Returns the Fino::Definition::Setting that describes this setting.
  attr_reader :definition

  # Returns the global (default/persisted) value, before any scope resolution.
  attr_reader :global_value

  # Returns a Hash of scope overrides (+{ "scope_name" => value }+).
  attr_reader :overrides

  # Returns the Fino::AbTesting::Experiment for this setting, or +nil+.
  attr_reader :experiment

  def initialize(definition, global_value, overrides = {}, experiment = nil)
    @definition = definition
    @global_value = global_value
    @overrides = overrides
    @experiment = experiment
  end

  # Returns the resolved value for this setting.
  #
  # Without a +for:+ context key, returns the global value. With +for:+,
  # checks overrides first, then A/B experiment variants, falling back to
  # the global value.
  #
  #   setting.value                  #=> "gpt-5"
  #   setting.value(for: "qa")       #=> "local_model"
  def value(**context)
    return global_value unless (scope = context[:for])

    overrides.fetch(scope.to_s) do
      return global_value unless experiment

      value = experiment.value(for: scope)
      return global_value if value == Fino::AbTesting::Variant::CONTROL_VALUE

      value
    end
  end

  # Returns the Symbol name of this setting.
  def name
    definition.setting_name
  end

  # Returns the storage key string (e.g. +"openai/model"+).
  def key
    definition.key
  end

  # Returns the Symbol type identifier (e.g. +:string+, +:integer+).
  def type
    definition.type
  end

  # Returns the type class (e.g. Fino::Settings::String).
  def type_class
    definition.type_class
  end

  # Returns the Fino::Definition::Section this setting belongs to, or +nil+.
  def section_definition
    definition.section_definition
  end

  # Returns the Symbol section name, or +nil+ for top-level settings.
  def section_name
    definition.section_definition&.name
  end

  # Returns the default value for this setting (deserialized).
  def default
    definition.default
  end

  # Returns the description string, or +nil+.
  def description
    definition.description
  end

  # Returns +true+ if this setting has any scoped overrides.
  def overriden?
    !overrides.empty?
  end

  # Returns +true+ if this setting has an A/B testing experiment attached.
  def ab_tested?
    !!experiment
  end

  private

  def inspectable_attributes
    {
      key: key,
      type: type_class,
      default: default,
      global_value: global_value
    }.tap do |attributes|
      attributes[:overrides] = overrides if overriden?
      attributes[:experiment] = experiment if ab_tested?
    end
  end
end
