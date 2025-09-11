# frozen_string_literal: true

Fino::Rails::Engine.routes.draw do
  root to: "settings#index"

  get "settings/*key", to: "settings#edit", as: :edit_setting
  put "settings/*key", to: "settings#update", as: :update_setting
end
