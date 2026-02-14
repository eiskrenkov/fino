# frozen_string_literal: true

# Mixin providing feature toggle convenience methods for Fino::Library.
#
# Adds +enabled?+, +disabled?+, +enable+, and +disable+ methods that
# work exclusively with boolean settings. These methods raise +ArgumentError+
# if called on a non-boolean setting.
#
#   Fino.enabled?(:maintenance_mode)            #=> false
#   Fino.enable(:maintenance_mode, for: "qa")
#   Fino.enabled?(:maintenance_mode, for: "qa") #=> true
module Fino::Library::FeatureTogglesSupport
  # Returns +true+ if the boolean setting is enabled.
  #
  #   Fino.enabled?(:new_ui, at: :feature_toggles)                  #=> true
  #   Fino.enabled?(:new_ui, at: :feature_toggles, for: "beta")     #=> false
  #
  # +setting_name+ - Symbol name of a boolean setting.
  # +at+ - Optional Symbol section name.
  # +context+ - Optional keyword arguments (+for:+ scope).
  #
  # Raises +ArgumentError+ if the setting is not a boolean type.
  def enabled?(setting_name, at: nil, **context)
    setting = setting(setting_name, at: at)
    ensure_setting_is_boolean!(setting.definition)

    setting.enabled?(**context)
  end

  # Returns +true+ if the boolean setting is disabled.
  #
  # Inverse of #enabled?. See #enabled? for parameter details.
  #
  # Raises +ArgumentError+ if the setting is not a boolean type.
  def disabled?(setting_name, at: nil, **context)
    setting = setting(setting_name, at: at)
    ensure_setting_is_boolean!(setting.definition)

    setting.disabled?(**context)
  end

  # Enables a boolean setting globally or for a specific scope.
  #
  # When +for:+ is provided, adds a scoped override rather than changing the
  # global value.
  #
  #   Fino.enable(:maintenance_mode)
  #   Fino.enable(:maintenance_mode, for: "qa")
  #
  # +setting_name+ - Symbol name of a boolean setting.
  # +at+ - Optional Symbol section name.
  # +for+ - Optional scope identifier for a scoped override.
  #
  # Raises +ArgumentError+ if the setting is not a boolean type.
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

  # Disables a boolean setting globally or for a specific scope.
  #
  # When +for:+ is provided, adds a scoped override rather than changing the
  # global value.
  #
  #   Fino.disable(:maintenance_mode)
  #   Fino.disable(:maintenance_mode, for: "qa")
  #
  # +setting_name+ - Symbol name of a boolean setting.
  # +at+ - Optional Symbol section name.
  # +for+ - Optional scope identifier for a scoped override.
  #
  # Raises +ArgumentError+ if the setting is not a boolean type.
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
