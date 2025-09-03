# frozen_string_literal: true

class Fino::UI::SettingsController < Fino::UI::ApplicationController
  def index
    @settings = Fino.library.all
  end

  def edit
    setting_path = parse_setting_path(params[:key])

    @setting = Fino.setting(*setting_path)
  end

  def update
    begin
      # Parse the key to create the setting path
      setting_path = parse_setting_path(params[:key])

      # Update the setting using the correct API
      Fino.set(params[:value], *setting_path)

      redirect_to root_path, notice: "Setting updated successfully"
    rescue Fino::Registry::UnknownSetting
      redirect_to root_path, alert: "Setting not found"
    end
  end

  private

  def parse_setting_path(key)
    key.split('.').map(&:to_sym).reverse
  end
end
