# frozen_string_literal: true

class Fino::Settings::Boolean
  include Fino::Setting

  class << self
    def serialize(value)
      value ? "1" : "0"
    end

    def deserialize(raw_value)
      raw_value == "1"
    end
  end
end
