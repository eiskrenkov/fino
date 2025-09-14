# frozen_string_literal: true

class Fino::Rails::SettingsController < Fino::Rails::ApplicationController
  def index
    @settings = Fino.settings
  end

  def edit
    @setting = Fino.setting(setting_name, at: section_name)
  end

  def update
    Fino.set(setting_name => params[:value], at: section_name)

    redirect_to root_path, notice: "Setting updated successfully"
  rescue Fino::Registry::UnknownSetting
    redirect_to root_path, alert: "Setting not found"
  end

  private

  def setting_name
    params[:setting]
  end

  def section_name
    case params[:section]
    when "general" then nil
    else params[:section]
    end
  end
end
