# frozen_string_literal: true

class Fino::Pipeline
  extend Forwardable

  def_delegators :pipeline, *Fino::Pipe.public_instance_methods

  def initialize(storage, pipes = [])
    @storage = storage
    @pipes = pipes
    @pipe_wrapper = ->(pipe) { pipe }
  end

  def use(pipe_class, *args, **kwargs, &block)
    pipes.unshift ->(pipe) { pipe_class.new(pipe, *args, **kwargs, &block) }
    @pipeline = nil
  end

  def wrap(&block)
    @pipe_wrapper = block
    @pipeline = nil
  end

  private

  attr_reader :storage, :pipes, :pipe_wrapper

  def pipeline
    @pipeline ||= pipes.inject(pipe_wrapper.call(storage)) do |pipe, builder|
      pipe_wrapper.call(builder.call(pipe))
    end
  end
end
