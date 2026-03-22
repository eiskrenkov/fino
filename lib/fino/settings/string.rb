# frozen_string_literal: true

class Fino::Settings::String
  include Fino::Setting

  self.type_identifier = :string

  class << self
    def serialize(_setting_definition, value)
      value
    end

    def deserialize(_setting_definition, raw_value)
      raw_value
    end
  end
end
