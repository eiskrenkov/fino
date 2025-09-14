# frozen_string_literal: true

class Fino::Rails::DashboardController < Fino::Rails::ApplicationController
  def index
    @settings = Fino.settings
  end
end
