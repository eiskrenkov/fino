# frozen_string_literal: true

module Fino::Rails::ApplicationHelper
  FLASH_TYPE_TO_COLOR_MAPPING = {
    notice: "green",
    alert: "red"
  }.freeze

  def fino_asset_path(file, version: true)
    path = "#{Rails.application.config.relative_url_root}/fino-assets/#{file}".gsub("//", "/")
    version ? "#{path}?v=#{Fino::VERSION}" : path
  end

  def color_for_flash_type(flash_type)
    FLASH_TYPE_TO_COLOR_MAPPING.fetch(flash_type.to_sym, "blue")
  end
end
