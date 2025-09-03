# frozen_string_literal: true

Fino::UI::Engine.routes.draw do
  root to: "settings#index"

  resources :settings, only: [:index, :edit, :update], param: :key, constraints: { key: /[^\/]+/ }
end
