# frozen_string_literal: true

class Fino::Pipeline
  extend Forwardable

  def_delegators :pipeline, *Fino::Pipe.public_instance_methods

  def initialize(storage, pipes = [])
    @storage = storage
    @pipes = pipes
  end

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
