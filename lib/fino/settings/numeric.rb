# frozen_string_literal: true

module Fino::Settings::Numeric
  module Unit
    class Generic
      attr_reader :name, :short_name

      def initialize(name, short_name = nil)
        @name = name
        @short_name = short_name || name
      end
    end

    class Milliseconds < Generic
      def initialize = super("Milliseconds", "ms")
    end

    module_function

    def for(identifier)
      case identifier
      when :ms
        Milliseconds.new
      else
        Generic.new(identifier.to_s.capitalize)
      end
    end
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
