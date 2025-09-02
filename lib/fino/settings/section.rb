# frozen_string_literal: true

class Fino::Settings::Section
  attr_reader :name, :label, :settings

  def initialize(name = nil, label: nil)
    @name = name
    @label = label

    @settings = {}
  end
end
