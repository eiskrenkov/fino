# frozen_string_literal: true

Fino::Rails::Engine.routes.draw do
  root to: "settings#index"

  resources :settings, only: %i[index edit update], param: :key
end
