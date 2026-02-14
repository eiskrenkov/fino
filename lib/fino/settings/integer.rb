# frozen_string_literal: true

# Integer setting type. Values are stored as strings and parsed via +to_i+.
#
# Includes Fino::Settings::Numeric for unit conversion support.
#
# Registered as +:integer+ in the settings DSL.
#
#   setting :api_rate_limit, :integer, default: 1000
#   setting :timeout, :integer, unit: :ms, default: 200
class Fino::Settings::Integer
  include Fino::Setting
  include Fino::Settings::Numeric

  self.type_identifier = :integer

  class << self
    # Converts an Integer to a String for storage.
    def serialize(value)
      value.to_s
    end

    # Parses a stored string back to an Integer.
    def deserialize(raw_value)
      raw_value.to_i
    end
  end
end
