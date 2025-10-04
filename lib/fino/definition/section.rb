# frozen_string_literal: true

class Fino::Definition::Section
  attr_reader :name, :options

  def initialize(name:, **options)
    @name = name
    @options = options
  end

  def label
    options.fetch(:label, name.to_s.capitalize)
  end

  def eql?(other)
    self.class.eql?(other.class) && name == other.name
  end
  alias == eql?

  def hash
    name.hash
  end
end
