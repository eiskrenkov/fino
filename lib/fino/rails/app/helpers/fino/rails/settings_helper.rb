# frozen_string_literal: true

module Fino::Rails::SettingsHelper
  SETTING_TYPE_TO_COLOR_MAPPING = {
    string: "pink",
    boolean: "blue",
    integer: "yellow",
    float: "purple"
  }

  def setting_type_label(setting)
    color = SETTING_TYPE_TO_COLOR_MAPPING.fetch(setting.type, "gray")

    tag.div class: "flex-none rounded-full bg-#{color}-50 px-2 py-1 text-xs font-medium text-#{color}-700 inset-ring inset-ring-#{color}-700/10" do
      setting.type.to_s.titleize
    end
  end
end
