# frozen_string_literal: true

# Float setting type. Values are stored as strings and parsed via +to_f+.
#
# Includes Fino::Settings::Numeric for unit conversion support.
#
# Registered as +:float+ in the settings DSL.
#
#   setting :temperature, :float, default: 0.7
class Fino::Settings::Float
  include Fino::Setting
  include Fino::Settings::Numeric

  self.type_identifier = :float

  class << self
    # Converts a Float to a String for storage.
    def serialize(value)
      value.to_s
    end

    # Parses a stored string back to a Float.
    def deserialize(raw_value)
      raw_value.to_f
    end
  end
end
