# frozen_string_literal: true

module Fino::Pipe
  def initialize(pipe)
    @pipe = pipe
  end

  def read(setting_definition)
    raise NotImplementedError
  end

  def read_multi(setting_definitions)
    raise NotImplementedError
  end

  def write(setting_definition, value, overrides, variants)
    raise NotImplementedError
  end

  private

  attr_reader :pipe
end
