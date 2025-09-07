# frozen_string_literal: true

Rails.application.routes.draw do
  mount Fino::Rails::Engine => "/fino"
end
