# frozen_string_literal: true

require "delegate"
require "active_support/notifications"

class Fino::Rails::Instrumentation::Cache < SimpleDelegator
  include Fino::Rails::Instrumentation

  self.instrumentation_namespace = "cache.fino"

  alias cache __getobj__

  def read(key)
    instrument(__method__, key: key) do
      cache.read(key)
    end
  end

  def write(key, ...)
    instrument(__method__, key: key) do
      cache.write(key, ...)
    end
  end

  def fetch(key, ...)
    instrument(__method__, key: key) do
      cache.fetch(key, ...)
    end
  end

  def fetch_multi(*keys, &block)
    instrument(__method__, keys: keys.join(", ")) do
      cache.fetch_multi(*keys, &block)
    end
  end

  def delete(key)
    instrument(__method__, key: key) do
      cache.delete(key)
    end
  end
end
