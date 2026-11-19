# frozen_string_literal: true

class Fino::Rails::SectionsController < Fino::Rails::ApplicationController
  def show
    @settings = Fino.settings(at: current_section.name)
    load_setting_meta(@settings)
  end
end
