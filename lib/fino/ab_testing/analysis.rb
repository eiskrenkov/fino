# frozen_string_literal: true

class Fino::AbTesting::Analysis
  class VariantData
    attr_reader :variant, :conversions_count, :daily_conversions

    def initialize(variant:, conversions_count:, daily_conversions:)
      @variant = variant
      @conversions_count = conversions_count
      @daily_conversions = daily_conversions
    end
  end

  class << self
    def from_raw_conversions(setting_instance, raw_conversions) # rubocop:disable Metrics/MethodLength
      experiment = setting_instance.experiment

      variants_data = experiment.variants.map do |variant|
        entries = raw_conversions.fetch(variant, [])

        daily_conversions = entries
                            .group_by { |_scope, score| Time.at(score / 1000.0).to_date.to_s }
                            .transform_values(&:size)

        Fino::AbTesting::Analysis::VariantData.new(
          variant: variant,
          conversions_count: entries.size,
          daily_conversions: daily_conversions
        )
      end

      Fino::AbTesting::Analysis.new(variants_data)
    end
  end

  attr_reader :variants_data

  def initialize(variants_data)
    @variants_data = variants_data
  end

  def any_conversions?
    variants_data.any? { |vd| vd.conversions_count > 0 }
  end

  def total_conversions
    variants_data.sum(&:conversions_count)
  end
end
