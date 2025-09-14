# frozen_string_literal: true

class Fino::Rails::ApplicationController < ActionController::Base
  GENERAL_SECTION = Fino::Definition::Section.new(name: nil, label: "General")

  helper Fino::Rails::ApplicationHelper
  helper Fino::Rails::SettingsHelper

  def sections
    @sections ||= [
      GENERAL_SECTION,
      *Fino.registry.section_definitions
    ]
  end

  def current_section
    return @current_section if defined?(@current_section)

    section_name = params[:section]&.to_sym

    @current_section =
      case section_name
      when :general
        GENERAL_SECTION
      else
        Fino.registry.section_definitions.find { |s| s.name == params[:section]&.to_sym }
      end
  end

  helper_method :sections, :current_section
end
