# frozen_string_literal: true

class Fino::Settings::Integer
  include Fino::Setting
  include Fino::Settings::Numeric

  self.type_identifier = :integer

  class << self
    def serialize(_setting_definition, value)
      value.to_s
    end

    def deserialize(_setting_definition, raw_value)
      raw_value.to_i
    end
  end
end
