# frozen_string_literal: true

require "forwardable"

class Fino::Library
  class Pipeline
    def initialize(pipes = [])
      @pipes = pipes
    end

    def use(pipe)
      @pipes << pipe
    end

    def read(setting_definition)
      traverse(setting_definition)
    end

    private

    def traverse(setting_definition, index = 0)
      @pipes[index]&.call(setting_definition) do
        traverse(setting_definition, index + 1)
      end
    end
  end

  def initialize(configuration)
    @configuration = configuration
  end

  def value(*setting_path)
    setting(*setting_path).value
  end

  def setting(*setting_path)
    pipeline.read(configuration.registry.fetch(*setting_path))
  end

  def all
    adapter.all
  end

  private

  attr_reader :configuration

  def pipeline
    @pipeline ||= Pipeline.new.tap do |p|
      p.use ->(setting_definition, &block) { cache.fetch(setting_definition, &block) }
      p.use ->(setting_definition, &block) { adapter.setting(setting_definition) }
    end
  end

  def cache
    return @cache if defined?(@cache)

    @cache = configuration.cache_builder_block&.call
  end

  def adapter
    @adapter ||= Fino::Adapter::Proxy.new(configuration.adapter_builder_block.call, configuration.registry)
  end
end
