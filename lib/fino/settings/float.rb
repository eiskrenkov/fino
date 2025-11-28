# frozen_string_literal: true

class Fino::Settings::Float
  include Fino::Setting
  include Fino::Settings::Numeric

  self.type_identifier = :float

  class << self
    def serialize(value)
      value.to_s
    end

    def deserialize(raw_value)
      raw_value.to_f
    end
  end
end
