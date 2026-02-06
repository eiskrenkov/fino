# frozen_string_literal: true

module Fino::Settings::Numeric
  module Unit
    class Generic
      attr_reader :name, :short_name

      def initialize(name, short_name = nil)
        @name = name
        @short_name = short_name || name
      end

      def base_factor
        1
      end

      def convertible_to?(_other)
        false
      end
    end

    module Time
      BASE_UNIT = :seconds

      def convertible_to?(other)
        other.is_a?(Time)
      end
    end

    class Milliseconds < Generic
      include Time

      def initialize = super("Milliseconds", "ms")

      def base_factor
        0.001
      end
    end

    class Seconds < Generic
      include Time

      def initialize = super("Seconds", "sec")

      def base_factor
        1
      end
    end

    module_function

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

  def value(**context)
    result = super
    return result unless (target_unit_identifier = context[:unit])

    raise ArgumentError, "No unit defined for this setting" unless unit

    target_unit = Unit.for(target_unit_identifier)
    raise ArgumentError, "Cannot convert #{unit.name} to #{target_unit.name}" unless unit.convertible_to?(target_unit)

    result * unit.base_factor / target_unit.base_factor
  end

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
