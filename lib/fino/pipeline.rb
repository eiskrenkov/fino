# frozen_string_literal: true

class Fino::Pipeline
  def initialize(pipes = [])
    @pipes = pipes
  end

  def append(pipe)
    raise ArgumentError, "Pipe must implement Fino::Pipe" unless pipe.is_a?(Fino::Pipe)
    @pipes << pipe
  end

  def prepend(pipe)
    raise ArgumentError, "Pipe must implement Fino::Pipe" unless pipe.is_a?(Fino::Pipe)
    @pipes.unshift(pipe)
  end

  def read(setting_definition)
    read_pipeline(setting_definition)
  end

  def read_multi(setting_definitions)
    @pipes.each do |pipe|
      settings = pipe.read_multi(setting_definitions)
      return settings if settings
    end
  end

  def write(value, setting_definition)
    @pipes.each do |pipe|
      pipe.write(setting_definition, value)
    end

    value
  end

  private

  def read_pipeline(setting_definition, pipe_index = 0)
    @pipes[pipe_index]&.read(setting_definition) do
      read_pipeline(setting_definition, pipe_index + 1)
    end
  end
end
