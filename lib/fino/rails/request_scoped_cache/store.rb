# frozen_string_literal: true

class Fino::Rails::RequestScopedCache::Store < Fino::Cache::Memory
  def initialize
    super(expires_in: nil)
  end
end
