# frozen_string_literal: true

class Fino::Settings::Float
  include Fino::Setting
  include Fino::Settings::Numeric

  self.type_identifier = :float

  class << self
    def serialize(_setting_definition, value)
      value.to_s
    end

    def deserialize(_setting_definition, raw_value)
      raw_value.to_f
    end
  end
end
