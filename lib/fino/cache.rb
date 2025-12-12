# frozen_string_literal: true

module Fino::Cache
  def exist?(key)
    raise NotImplementedError
  end

  def read(key)
    raise NotImplementedError
  end

  def write(key, value)
    raise NotImplementedError
  end

  def fetch(key, &)
    raise NotImplementedError
  end

  def fetch_multi(*keys, &block)
    raise NotImplementedError
  end

  def delete(key)
    raise NotImplementedError
  end

  def clear
    raise NotImplementedError
  end
end
