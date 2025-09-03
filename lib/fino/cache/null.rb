# frozen_string_literal: true

class Fino::Cache::Null
  include Fino::Cache

  def fetch(_key)
    yield
  end
end
