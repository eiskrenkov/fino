# frozen_string_literal: true

Fino::Rails::Engine.routes.draw do
  root to: "dashboard#index"

  get ":section", to: "sections#show", as: :settings_section

  get ":section/:setting", to: "settings#edit", as: :edit_setting
  put ":section/:setting", to: "settings#update", as: :update_setting
end
