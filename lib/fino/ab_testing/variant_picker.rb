# frozen_string_literal: true

require "zlib"

# Deterministically assigns a scope to a variant based on CRC32 hashing.
#
# The picker uses +Zlib.crc32+ on the concatenation of the setting key and
# scope to produce a stable hash. This ensures the same scope always receives
# the same variant (sticky assignment), without needing to store assignments.
class Fino::AbTesting::VariantPicker
  # Precision multiplier for percentage-based bucketing.
  SCALING_FACTOR = 1_000

  # Returns the Fino::Definition::Setting used to generate the hash key.
  attr_reader :setting_definition

  def initialize(setting_definition)
    @setting_definition = setting_definition
  end

  # Picks a variant for the given scope.
  #
  # +variants+ - Array of Fino::AbTesting::Variant instances (sorted by percentage).
  # +scope+ - A scope identifier (e.g. user ID string).
  #
  # Returns the selected Fino::AbTesting::Variant, or +nil+ if variants is empty.
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
