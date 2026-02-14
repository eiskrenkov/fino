# frozen_string_literal: true

# String setting type. Values are stored and returned as-is.
#
# Registered as +:string+ in the settings DSL.
#
#   setting :model, :string, default: "gpt-5"
class Fino::Settings::String
  include Fino::Setting

  self.type_identifier = :string

  class << self
    # Returns the value unchanged (strings need no conversion).
    def serialize(value)
      value
    end

    # Returns the raw value unchanged.
    def deserialize(raw_value)
      raw_value
    end
  end
end
