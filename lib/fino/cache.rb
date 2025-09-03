# frozen_string_literal: true

module Fino::Cache
  def fetch(key, &)
    raise NotImplementedError
  end

  def write(key, value)
    raise NotImplementedError
  end
end
