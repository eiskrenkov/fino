# frozen_string_literal: true

class Fino::Configuration
  attr_reader :registry, :adapter_builder_block, :cache_builder_block, :pipeline_builder_block

  def initialize(registry)
    @registry = registry
  end

  def adapter(&block)
    @adapter_builder_block = block
  end

  def cache(&block)
    @cache_builder_block = block
  end

  def pipeline(&block)
    @pipeline_builder_block = block
  end

  def settings(&)
    Fino::Registry::DSL.new(registry).instance_eval(&)
  end
end
