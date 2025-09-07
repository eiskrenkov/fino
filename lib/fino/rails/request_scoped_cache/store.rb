# frozen_string_literal: true

class Fino::Rails::RequestScopedCache::Store
  def initialize
    @data = {}
  end

  def fetch(key, &)
    @data.fetch(key, &)
  end

  def write(key, value)
    @data[key] = value
  end
end
