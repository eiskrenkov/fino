# frozen_string_literal: true

class Fino::Settings::String
  include Fino::Setting

  def cast(raw_value)
    raw_value.to_s
  end
end
