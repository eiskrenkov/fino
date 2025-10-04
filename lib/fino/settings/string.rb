# frozen_string_literal: true

class Fino::Settings::String
  include Fino::Setting

  self.type_identitfier = :string

  class << self
    def serialize(value)
      value
    end

    def deserialize(raw_value)
      raw_value
    end
  end
end
