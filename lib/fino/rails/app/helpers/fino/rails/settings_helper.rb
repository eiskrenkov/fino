# frozen_string_literal: true

module Fino::Rails::SettingsHelper
  SETTING_TYPE_TO_COLOR_MAPPING = {
    string: "pink",
    boolean: "blue",
    integer: "yellow",
    float: "purple"
  }.freeze

  def setting_type_label(setting)
    color = SETTING_TYPE_TO_COLOR_MAPPING.fetch(setting.type, "gray")

    tag.div class: "flex-none rounded-full bg-#{color}-50 px-2 py-1 text-xs font-medium text-#{color}-700 inset-ring inset-ring-#{color}-700/10" do
      setting.type.to_s.titleize
    end
  end

  def boolean_setting_status(setting)
    global_value = setting.value
    overrides = setting.overrides

    if overrides.empty?
      return {
        text: global_value ? "Enabled" : "Disabled",
        color: global_value ? "green" : "red"
      }
    end

    if global_value
      disabled_scopes = overrides.reject { |_, value| value }.keys

      if disabled_scopes.any?
        {
          short_text: "Conditionally enabled",
          text: "Enabled except for #{disabled_scopes.to_sentence}",
          color: "yellow"
        }
      else
        { text: "Enabled", color: "green" }
      end
    else
      enabled_scopes = overrides.select { |_, value| value }.keys

      if enabled_scopes.any?
        {
          short_text: "Conditionally enabled",
          text: "Enabled for #{enabled_scopes.to_sentence}",
          color: "yellow"
        }
      else
        { text: "Disabled", color: "red" }
      end
    end
  end
end
