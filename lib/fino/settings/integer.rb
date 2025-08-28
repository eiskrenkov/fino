# frozen_string_literal: true

class Fino::Settings::Integer
  include Fino::Setting

  def cast(raw_value)
    raw_value.to_i
  end
end
