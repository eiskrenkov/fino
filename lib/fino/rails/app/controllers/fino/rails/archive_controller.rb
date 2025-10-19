# frozen_string_literal: true

class Fino::Rails::ArchiveController < Fino::Rails::ApplicationController
  def index
    @archived_setting_keys = Fino.library.persisted_keys - Fino.settings.map(&:key)
  end
end
