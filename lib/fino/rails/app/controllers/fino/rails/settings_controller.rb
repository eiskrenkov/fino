# frozen_string_literal: true

class Fino::Rails::SettingsController < Fino::Rails::ApplicationController
  def index
    @settings = Fino.library.settings
  end

  def edit
    setting_name, at = parse_setting_path(params[:key])

    @setting = Fino.setting(setting_name, at: at)
  end

  def update
    setting_name, at = parse_setting_path(params[:key])

    Fino.set(setting_name => params[:value], at: at)

    redirect_to root_path, notice: "Setting updated successfully"
  rescue Fino::Registry::UnknownSetting
    redirect_to root_path, alert: "Setting not found"
  end

  private

  def parse_setting_path(key)
    key.split("/").map(&:to_sym).reverse
  end
end
