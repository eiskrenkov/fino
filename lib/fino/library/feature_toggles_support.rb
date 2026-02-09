# frozen_string_literal: true

module Fino::Library::FeatureTogglesSupport
  def enabled?(setting_name, at: nil, **context)
    setting = setting(setting_name, at: at)
    ensure_setting_is_boolean!(setting.definition)

    setting.enabled?(**context)
  end

  def disabled?(setting_name, at: nil, **context)
    setting = setting(setting_name, at: at)
    ensure_setting_is_boolean!(setting.definition)

    setting.disabled?(**context)
  end

  def enable(setting_name, for:, at: nil)
    setting_definition = build_setting_definition(setting_name, at: at)
    ensure_setting_is_boolean!(setting_definition)

    add_override(setting_name, at: at, binding.local_variable_get(:for) => true)
  end

  def disable(setting_name, for:, at: nil)
    setting_definition = build_setting_definition(setting_name, at: at)
    ensure_setting_is_boolean!(setting_definition)

    add_override(setting_name, at: at, binding.local_variable_get(:for) => false)
  end

  private

  def ensure_setting_is_boolean!(setting_definition)
    return if setting_definition.type_class == Fino::Settings::Boolean

    raise ArgumentError, "Setting #{setting_definition.key} is not a boolean"
  end
end
