# frozen_string_literal: true

# Composable pipeline for reading and writing settings.
#
# The pipeline wraps a base storage pipe with additional pipes (e.g. caching)
# using the decorator pattern. Pipes are stacked in order: the last pipe added
# is the outermost layer that handles requests first.
#
# == Usage
#
# Pipelines are built automatically by Fino::Library. Custom pipes can be
# added via the configuration DSL:
#
#   Fino.configure do
#     pipeline { |p| p.use MyCustomPipe, some_option }
#   end
#
# == Custom Pipes
#
# A pipe must include Fino::Pipe and implement +read+, +read_multi+,
# and +write+. Each pipe wraps the next pipe in the chain.
class Fino::Pipeline
  extend Forwardable

  def_delegators :pipeline, *Fino::Pipe.public_instance_methods

  def initialize(storage, pipes = [])
    @storage = storage
    @pipes = pipes
  end

  # Adds a pipe to the pipeline.
  #
  # +pipe_class+ - A class that includes Fino::Pipe.
  # Additional arguments are forwarded to the pipe constructor.
  #
  #   pipeline.use Fino::Pipe::Cache, cache_instance
  def use(pipe_class, ...)
    pipes << ->(pipe) { pipe_class.new(pipe, ...) }
    @pipeline = nil
  end

  private

  attr_reader :storage, :pipes

  def pipeline
    @pipeline ||= pipes.inject(storage) do |pipe, builder|
      builder.call(pipe)
    end
  end
end
