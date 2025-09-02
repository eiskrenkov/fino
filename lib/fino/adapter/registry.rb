# frozen_string_literal: true

class Fino::Adapter::Registry
  include Singleton
  extend SingleForwardable

  def_delegators :instance, :register, :fetch, :all

  def initialize
    @adapters = {}
  end

  def register(name, adapter_class)
    @adapters[name.to_sym] = adapter_class
  end

  def fetch(name)
    @adapters.fetch(name.to_sym) { raise KeyError, "Adapter not found: #{name}" }
  end

  def all
    @adapters.dup
  end
end
