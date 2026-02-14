# frozen_string_literal: true

# Holds configuration for a Fino instance.
#
# Fino::Configuration is evaluated via the block passed to Fino.configure.
# It provides a DSL for specifying the storage adapter, cache, pipeline
# customizations, and setting definitions.
#
# == Example
#
#   Fino.configure do
#     adapter { Fino::Redis::Adapter.new(Redis.new) }
#     cache(if: -> { Rails.env.production? }) { Fino::Cache::Memory.new(expires_in: 3) }
#
#     wrap_adapter { |adapter| InstrumentedAdapter.new(adapter) }
#     wrap_cache { |cache| InstrumentedCache.new(cache) }
#
#     pipeline { |p| p.use CustomPipe }
#
#     settings do
#       setting :api_limit, :integer, default: 1000
#       section :openai do
#         setting :model, :string, default: "gpt-5"
#       end
#     end
#   end
class Fino::Configuration
  # Returns the Fino::Registry holding setting and section definitions.
  attr_reader :registry

  # Returns the pipeline builder block, if one was configured via +pipeline+.
  attr_reader :pipeline_builder_block

  def initialize(registry)
    @registry = registry
  end

  # Returns the callable that builds the storage adapter.
  #
  # If +wrap_adapter+ was called, returns the wrapping proc; otherwise returns
  # the block passed to +adapter+.
  def adapter_builder_block
    @wrapped_adapter_builder_block || @adapter_builder_block
  end

  # Registers a block that builds the storage adapter.
  #
  # The block is called lazily when the adapter is first needed.
  #
  #   adapter { Fino::Redis::Adapter.new(redis) }
  def adapter(&block)
    @adapter_builder_block = block
  end

  # Wraps the adapter built by +adapter+ with additional behavior.
  #
  # The block receives the original adapter instance and should return
  # a wrapped adapter implementing the same Fino::Adapter interface.
  #
  #   wrap_adapter { |adapter| InstrumentedAdapter.new(adapter) }
  def wrap_adapter(&block)
    @wrapped_adapter_builder_block = proc { block.call(@adapter_builder_block.call) }
  end

  # Returns the callable that builds the cache, or +nil+ if caching is
  # disabled or the +if:+ condition returned false.
  def cache_builder_block
    @cache_builder_block && (@wrapped_cache_builder_block || @cache_builder_block)
  end

  # Registers a block that builds the cache.
  #
  # The optional +if:+ parameter accepts a callable that determines whether
  # caching should be enabled. When the callable returns false, the cache
  # block is ignored.
  #
  #   cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }
  #   cache(if: -> { Rails.env.production? }) { Fino::Cache::Memory.new(expires_in: 5) }
  def cache(if: -> { true }, &block)
    return unless binding.local_variable_get(:if).call

    @cache_builder_block = block
  end

  # Wraps the cache built by +cache+ with additional behavior.
  #
  # The block receives the original cache instance and should return
  # a wrapped cache implementing the same Fino::Cache interface.
  #
  #   wrap_cache { |cache| InstrumentedCache.new(cache) }
  def wrap_cache(&block)
    @wrapped_cache_builder_block = proc { block.call(@cache_builder_block&.call) }
  end

  # Registers a block for customizing the pipeline.
  #
  # The block receives the Fino::Pipeline instance and can add custom pipes.
  #
  #   pipeline { |p| p.use MyCustomPipe }
  def pipeline(&block)
    @pipeline_builder_block = block
  end

  # Opens the settings definition DSL.
  #
  # The block is evaluated in the context of Fino::Registry::DSL, providing
  # +setting+ and +section+ methods.
  #
  #   settings do
  #     setting :timeout, :integer, default: 30
  #     section :openai do
  #       setting :model, :string, default: "gpt-5"
  #     end
  #   end
  def settings(&)
    Fino::Registry::DSL.new(registry).instance_eval(&)
  end
end
