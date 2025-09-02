# frozen_string_literal: true

class Fino::Configuration
  attr_reader :registry, :adapter_instance, :cache_instance

  def initialize(registry)
    @registry = registry

    @cache_instance = Fino::Cache::Null.new
  end

  def adapter(adapter_name, **options)
    @adapter_instance = Fino::Adapter::Registry.fetch(adapter_name.to_sym).new(registry, **options)
  end

  def cache(cache_name, **options)
    # @cache_instance = Fino::Cache::Null.new
  end

  def settings(&)
    Fino::Registry::DSL.new(registry).instance_eval(&)
  end
end
