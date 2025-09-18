# frozen_string_literal: true

class Fino::VariantPicker
  SCALING_FACTOR = 1_000

  attr_reader :setting

  def initialize(setting)
    @setting = setting
  end

  def call(scope)
    return nil if setting.variants.empty?

    random = Zlib.crc32("#{setting.key}#{scope}") % (100 * SCALING_FACTOR)
    cumulative = 0

    picked_variant = setting.variants.sort_by(&:percentage).find do |variant|
      cumulative += variant.percentage * SCALING_FACTOR
      random <= cumulative
    end

    Fino.logger.debug { "Variant picked: #{picked_variant}" }

    picked_variant
  end
end
