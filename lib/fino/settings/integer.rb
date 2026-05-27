# frozen_string_literal: true

Fino::UnableToDeserializeValue = Class.new(Fino::Error)

class Fino::Settings::Integer
  include Fino::Setting
  include Fino::Settings::Numeric

  self.type_identifier = :integer

  class << self
    def serialize(_setting_definition, value)
      value.to_s
    end

    def deserialize(_setting_definition, raw_value)
      Integer(raw_value)
    rescue ArgumentError
      raise Fino::UnableToDeserializeValue
    end
  end
end
