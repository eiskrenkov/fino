# frozen_string_literal: true

# Boolean setting type, used for feature toggles and on/off flags.
#
# Serializes to +"1"+ / +"0"+ and deserializes a range of truthy representations
# (+"1"+, +1+, +true+, +"true"+, +"t"+, +"yes"+, +"y"+).
#
# Provides +enabled?+ and +disabled?+ convenience methods.
#
# Registered as +:boolean+ in the settings DSL.
#
#   setting :maintenance_mode, :boolean, default: false
class Fino::Settings::Boolean
  include Fino::Setting

  self.type_identifier = :boolean

  class << self
    # Serializes a boolean to +"1"+ (true) or +"0"+ (false).
    def serialize(value)
      value ? "1" : "0"
    end

    # Deserializes a raw value to +true+ or +false+.
    #
    # Truthy values: +"1"+, +1+, +true+, +"true"+, +"t"+, +"yes"+, +"y"+.
    # Everything else is +false+.
    def deserialize(raw_value)
      case raw_value
      when "1", 1, true, "true", "t", "yes", "y" then true
      else false
      end
    end
  end

  # Returns +true+ if the setting value is truthy for the given context.
  #
  #   setting.enabled?                #=> true
  #   setting.enabled?(for: "beta")   #=> false
  def enabled?(**context)
    value(**context)
  end

  # Returns +true+ if the setting value is falsy for the given context.
  def disabled?(**context)
    !enabled?(**context)
  end
end
