# frozen_string_literal: true

module Fino::Setting
  attr_reader :key, :section, :raw_value

  def initialize(key:, section:, raw_value:)
    @key = key
    @section = section
    @raw_value = raw_value
  end

  def value
    @value ||= cast(raw_value)
  end

  def cast(raw_value)
    raise NotImplementedError
  end
end
