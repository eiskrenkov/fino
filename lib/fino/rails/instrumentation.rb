# frozen_string_literal: true

require "active_support/concern"
require "active_support/class_attribute"

module Fino::Rails::Instrumentation
  extend ActiveSupport::Concern

  included do
    class_attribute :instrumentation_namespace, instance_accessor: false
  end

  private

  def instrument(method_name, payload)
    ActiveSupport::Notifications.instrument(self.class.instrumentation_namespace, payload) do |instrumentation_payload|
      instrumentation_payload[:class_name] = __getobj__.class.name
      instrumentation_payload[:method_name] = method_name

      yield.tap do |result|
        instrumentation_payload[:result] = result
      end
    end
  end
end
