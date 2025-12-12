# frozen_string_literal: true

class Api::SettingsController < ApplicationController
  def show
    render json: Fino.value(setting_name, at: section_name)
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
