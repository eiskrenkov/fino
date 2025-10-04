# frozen_string_literal: true

class Fino::Settings::Integer
  include Fino::Setting

  self.type_identitfier = :integer

  class << self
    def serialize(value)
      value.to_s
    end

    def deserialize(raw_value)
      raw_value.to_i
    end
  end
end
