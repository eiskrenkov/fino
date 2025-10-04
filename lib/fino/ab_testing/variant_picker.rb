# frozen_string_literal: true

class Fino::AbTesting::VariantPicker
  SCALING_FACTOR = 1_000

  attr_reader :setting_definition

  def initialize(setting_definition)
    @setting_definition = setting_definition
  end

  def call(variants, scope)
    return nil if variants.empty?

    random = Zlib.crc32("#{setting_definition.key}#{scope}") % (100 * SCALING_FACTOR)
    cumulative = 0

    picked_variant = variants.sort_by(&:percentage).find do |variant|
      cumulative += variant.percentage * SCALING_FACTOR
      random <= cumulative
    end

    Fino.logger.debug { "Variant picked: #{picked_variant}" }

    picked_variant
  end
end
