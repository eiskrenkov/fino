# frozen_string_literal: true

module Fino::Rails::ApplicationHelper
  def fino_asset_path(file, version: true)
    path = "#{Rails.application.config.relative_url_root}/fino-assets/#{file}".gsub("//", "/")
    version ? "#{path}?v=#{Fino::VERSION}" : path
  end
end
