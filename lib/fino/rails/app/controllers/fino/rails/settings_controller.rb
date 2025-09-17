# frozen_string_literal: true

class Fino::Rails::SettingsController < Fino::Rails::ApplicationController
  before_action :store_return_location, only: [:edit]

  def index
    @settings = Fino.settings
  end

  def edit
    @setting = Fino.setting(setting_name, at: section_name)
  end

  def update
    Fino.set(setting_name => params[:value], at: section_name)

    process_scope_overrides(params[:overrides]) if params[:overrides].present?

    redirect_to return_path, notice: "Setting updated successfully"
  rescue StandardError => e
    redirect_to return_path, alert: "Failed to update setting: #{e.message}"
  end

  private

  def return_path
    session.delete(:return_to) || root_path
  end

  def setting_name
    params[:setting]
  end

  def section_name
    case params[:section]
    when "general" then nil
    else params[:section]
    end
  end

  def process_scope_overrides(overrides_params)
    overrides_params.each_value do |override_data|
      scope = override_data[:scope]
      value = override_data[:value]

      next if scope.blank?
      next if value.nil? || (value.is_a?(String) && value.empty?)

      Fino.set(setting_name => value, scope: scope.to_sym, at: section_name)
    end
  end

  def store_return_location
    session[:return_to] = request.referer
  end
end
