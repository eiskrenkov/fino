# frozen_string_literal: true

class Fino::UI::SettingsController < Fino::UI::ApplicationController
  def index
    @settings = Fino.library.all

    render action: :index
  end
end
