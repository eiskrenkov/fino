# frozen_string_literal: true

class Fino::UI::SettingsController < Fino::UI::ApplicationController
  def index
    @settings = Fino.library.all

    prepend_view_path(File.join(Fino.root, "lib", "fino", "ui", "app", "views")) # TODO: Remove

    render action: :index
  end
end
