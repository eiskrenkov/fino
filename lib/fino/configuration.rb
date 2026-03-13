# frozen_string_literal: true

class Fino::Configuration
  attr_reader :registry, :pipeline_builder_block, :after_write_block

  def initialize(registry)
    @registry = registry
  end

  def adapter_builder_block
    @wrapped_adapter_builder_block || @adapter_builder_block
  end

  def adapter(&block)
    @adapter_builder_block = block
  end

  def wrap_adapter(&block)
    @wrapped_adapter_builder_block = proc { block.call(@adapter_builder_block.call) }
  end

  def cache_builder_block
    @cache_builder_block && (@wrapped_cache_builder_block || @cache_builder_block)
  end

  def cache(if: -> { true }, &block)
    return unless binding.local_variable_get(:if).call

    @cache_builder_block = block
  end

  def wrap_cache(&block)
    @wrapped_cache_builder_block = proc { block.call(@cache_builder_block&.call) }
  end

  def pipeline(&block)
    @pipeline_builder_block = block
  end

  def after_write(&block)
    @after_write_block = block
  end

  def settings(&)
    Fino::Registry::DSL.new(registry).instance_eval(&)
  end
end
