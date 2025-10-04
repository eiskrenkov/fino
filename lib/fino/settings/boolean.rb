# frozen_string_literal: true

class Fino::Settings::Boolean
  include Fino::Setting

  self.type_identifier = :boolean

  class << self
    def serialize(value)
      value ? "1" : "0"
    end

    def deserialize(raw_value)
      case raw_value
      when "1", 1, true, "true", "t", "yes", "y" then true
      else false
      end
    end
  end
end
