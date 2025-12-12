# frozen_string_literal: true

require "delegate"
require "active_support/notifications"

class Fino::Rails::Instrumentation::Adapter < SimpleDelegator
  include Fino::Rails::Instrumentation

  self.instrumentation_namespace = "adapter.fino"

  alias adapter __getobj__

  def read(setting_key)
    instrument(__method__, key: setting_key) do
      adapter.read(setting_key)
    end
  end

  def read_multi(*setting_keys)
    instrument(__method__, key: setting_keys.join(", ")) do
      adapter.read_multi(*setting_keys)
    end
  end

  def write(setting_deginition, ...)
    instrument(__method__, key: setting_deginition.key) do
      adapter.write(setting_deginition, ...)
    end
  end
end
