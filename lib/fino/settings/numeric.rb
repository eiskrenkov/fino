# frozen_string_literal: true

# Mixin for numeric setting types (Integer, Float) that adds unit conversion.
#
# When a setting is defined with a +unit:+ option, its value can be converted
# to a different compatible unit at read time via the +unit:+ context key.
#
# == Supported Units
#
# Time units are interconvertible:
# - +:ms+ / +:milliseconds+ -- Fino::Settings::Numeric::Unit::Milliseconds
# - +:sec+ / +:seconds+ -- Fino::Settings::Numeric::Unit::Seconds
#
# == Example
#
#   # Define with unit
#   setting :http_read_timeout, :integer, unit: :ms, default: 200
#
#   # Read in different unit
#   Fino.value(:http_read_timeout, at: :svc)              #=> 200
#   Fino.value(:http_read_timeout, at: :svc, unit: :sec)  #=> 0.2
module Fino::Settings::Numeric
  # Namespace for unit types used in numeric setting conversion.
  module Unit
    # Base class for all unit types.
    #
    # Custom units can subclass Generic and override +base_factor+ and
    # +convertible_to?+ to enable conversions.
    class Generic
      # Returns the full name of the unit (e.g. "Milliseconds").
      attr_reader :name

      # Returns the abbreviated name (e.g. "ms").
      attr_reader :short_name

      def initialize(name, short_name = nil)
        @name = name
        @short_name = short_name || name
      end

      # Returns the factor to convert this unit to the base unit.
      def base_factor
        1
      end

      # Returns +false+ by default. Override in subclasses to enable conversion.
      def convertible_to?(_other)
        false
      end
    end

    # Mixin for time-based units, enabling conversion between them.
    module Time
      # The base unit for time conversions.
      BASE_UNIT = :seconds

      # Returns +true+ if the other unit also includes Time.
      def convertible_to?(other)
        other.is_a?(Time)
      end
    end

    # Milliseconds time unit. Base factor: 0.001 (relative to seconds).
    class Milliseconds < Generic
      include Time

      def initialize = super("Milliseconds", "ms")

      def base_factor
        0.001
      end
    end

    # Seconds time unit. Base factor: 1 (the base time unit).
    class Seconds < Generic
      include Time

      def initialize = super("Seconds", "sec")

      def base_factor
        1
      end
    end

    module_function

    # Returns a Unit instance for the given identifier.
    #
    # +identifier+ - Symbol or String (+:ms+, +:sec+, +:milliseconds+, +:seconds+).
    #
    # Unrecognized identifiers return a Generic unit (not convertible).
    def for(identifier)
      case identifier.to_s
      when "ms", "milliseconds"
        Milliseconds.new
      when "sec", "seconds"
        Seconds.new
      else
        Generic.new(identifier.to_s.capitalize)
      end
    end
  end

  # Returns the resolved value, optionally converted to a target unit.
  #
  # Pass +unit:+ in the context to request unit conversion.
  #
  #   setting.value                 #=> 200
  #   setting.value(unit: :sec)     #=> 0.2
  #
  # Raises +ArgumentError+ if no unit is defined on the setting or the
  # units are not convertible.
  def value(**context)
    result = super
    return result unless (target_unit_identifier = context[:unit])

    raise ArgumentError, "No unit defined for this setting" unless unit

    target_unit = Unit.for(target_unit_identifier)
    raise ArgumentError, "Cannot convert #{unit.name} to #{target_unit.name}" unless unit.convertible_to?(target_unit)

    result * unit.base_factor / target_unit.base_factor
  end

  # Returns the Unit instance for this setting, or +nil+ if no unit is defined.
  def unit
    return unless (identifier = definition.options[:unit])

    @unit ||= Unit.for(identifier)
  end

  private

  def inspectable_attributes
    additional_attributes = {}
    additional_attributes[:unit] = unit.short_name if unit

    super.merge(additional_attributes)
  end
end
