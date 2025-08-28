# frozen_string_literal: true

class Fino::Configuration
  attr_writer :adapter, :cache

  def initialize(settings_registry)
    @settings_registry = settings_registry
    @adapter = nil
    @cache = nil
  end

  def settings(&)
    Fino::Registry::DSL.new(settings_registry).instance_eval(&)
  end

  private

  attr_reader :settings_registry, :adapter, :cache
end
