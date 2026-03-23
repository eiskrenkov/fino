# frozen_string_literal: true

module Fino::Library::AbTestingAnalysisSupport
  SettingNotAbTested = Class.new(Fino::Error)
  AdapterDoesNotSupportAbTestingAnalysis = Class.new(Fino::Error)

  def convert!(setting_name, at: nil, for: nil, time: Time.now)
    ensure_ab_testing_analysis_supported!

    scope = binding.local_variable_get(:for)

    setting_instance = fetch_ab_testable_setting(setting_name, at: at)
    variant = setting_instance.experiment.variant(for: scope)

    adapter.record_ab_testing_conversion(setting_instance.definition, variant, scope, time)
  end

  def convert(setting_name, at: nil, time: Time.now, **context)
    convert!(setting_name, at: at, time: time, **context)
  rescue SettingNotAbTested, AdapterDoesNotSupportAbTestingAnalysis
    nil
  end

  def analyse(setting_name, at: nil)
    ensure_ab_testing_analysis_supported!

    setting_instance = fetch_ab_testable_setting(setting_name, at: at)
    raw_conversions = adapter.read_ab_testing_conversions(
      setting_instance.definition,
      setting_instance.experiment.variants
    )

    Fino::AbTesting::Analysis.from_raw_conversions(setting_instance, raw_conversions)
  end

  def reset_analysis!(setting_name, at: nil)
    ensure_ab_testing_analysis_supported!

    setting_instance = fetch_ab_testable_setting(setting_name, at: at)
    adapter.clear_ab_testing_conversions(setting_instance.definition.key)
  end

  private

  def ensure_ab_testing_analysis_supported!
    return if adapter.supports_ab_testing_analysis?

    raise AdapterDoesNotSupportAbTestingAnalysis, "Adapter #{adapter.class.name} does not support A/B testing analysis"
  end

  def fetch_ab_testable_setting(setting_name, at: nil)
    setting(setting_name, at: at).tap do |setting_instance|
      raise SettingNotAbTested, "Setting #{setting_name} is not A/B tested" unless setting_instance.ab_tested?
    end
  end
end
