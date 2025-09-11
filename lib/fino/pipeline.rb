# frozen_string_literal: true

class Fino::Pipeline
  extend Forwardable

  def_delegators :pipeline, *Fino::Pipe.public_instance_methods

  def initialize(storage, pipes = [])
    @storage = storage
    @pipes = pipes
  end

  def use(pipe_class, *args, **kwargs, &block)
    pipes.unshift ->(pipe) { pipe_class.new(pipe, *args, **kwargs, &block) }
    @pipeline = nil
  end

  private

  attr_reader :storage, :pipes

  def pipeline
    @pipeline ||= pipes.inject(storage) { |pipe, builder| builder.call(pipe) }
  end
end
