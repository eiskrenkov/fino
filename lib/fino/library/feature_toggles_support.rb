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

  def enable(setting_name, at: nil, for: nil)
    setting_definition = build_setting_definition(setting_name, at: at)
    ensure_setting_is_boolean!(setting_definition)

    scope = binding.local_variable_get(:for)

    if scope
      add_override(setting_name, at: at, scope => true)
    else
      set(setting_name => true, at: at)
    end
  end

  def disable(setting_name, at: nil, for: nil)
    setting_definition = build_setting_definition(setting_name, at: at)
    ensure_setting_is_boolean!(setting_definition)

    scope = binding.local_variable_get(:for)

    if scope
      add_override(setting_name, at: at, scope => false)
    else
      set(setting_name => false, at: at)
    end
  end

  private

  def ensure_setting_is_boolean!(setting_definition)
    return if setting_definition.type_class == Fino::Settings::Boolean

    raise ArgumentError, "Setting #{setting_definition.key} is not a boolean"
  end
end
