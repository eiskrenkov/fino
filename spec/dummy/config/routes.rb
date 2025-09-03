# frozen_string_literal: true

Rails.application.routes.draw do
  mount Fino::UI::Engine => "/fino"
end
