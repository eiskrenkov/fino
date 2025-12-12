# frozen_string_literal: true

Rails.application.routes.draw do
  mount Fino::Rails::Engine => "/fino"

  root to: redirect("/fino")

  namespace :api do
    get "settings/:section/:setting", to: "settings#show"
  end
end
