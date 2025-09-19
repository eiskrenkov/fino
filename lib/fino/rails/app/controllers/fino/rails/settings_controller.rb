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
    Fino.set(
      setting_name => params[:value],
      at: section_name,
      overrides: overrides,
      variants: variants
    )

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

  def overrides
    params[:overrides].values.each_with_object({}) do |raw_override, memo|
      memo[raw_override[:scope]] = raw_override[:value] if raw_override[:scope]
    end
  end

  def variants
    params[:variants].values.each_with_object({}).with_index do |(raw_variant, memo), index|
      next if index.zero?
      next unless raw_variant[:percentage].to_f > 0.0

      memo[raw_variant[:percentage].to_f] = raw_variant[:value]
    end
  end

  def store_return_location
    session[:return_to] = request.referer
  end
end
