# frozen_string_literal: true

class Fino::Pipeline
  def initialize(pipes = [])
    @pipes = pipes
  end

  def use(pipe)
    @pipes << pipe
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
