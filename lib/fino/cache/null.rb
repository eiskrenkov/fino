class Fino::Cache::Null
  include Fino::Cache

  def fetch(key)
    yield
  end
end
