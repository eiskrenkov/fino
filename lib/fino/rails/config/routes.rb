# frozen_string_literal: true

Fino::Rails::Engine.routes.draw do
  root to: "dashboard#index"

  resources :archive, only: %i[index]

  scope "settings" do
    get ":section", to: "sections#show", as: :settings_section

    get ":section/:setting", to: "settings#edit", as: :edit_setting
    put ":section/:setting", to: "settings#update", as: :update_setting
    post ":section/:setting/refresh", to: "settings#refresh", as: :refresh_setting
    post ":section/:setting/reset_analysis", to: "settings#reset_analysis", as: :reset_analysis
  end
end
