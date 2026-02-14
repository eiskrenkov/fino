# frozen_string_literal: true

# Abstract interface for pipeline pipes.
#
# A pipe wraps another pipe (or the base storage) and can intercept
# +read+, +read_multi+, and +write+ operations. This enables composable
# concerns like caching, instrumentation, or request-scoped storage.
#
# == Implementing a Custom Pipe
#
#   class MyPipe
#     include Fino::Pipe
#
#     def read(setting_definition)
#       # pre-processing
#       result = pipe.read(setting_definition)
#       # post-processing
#       result
#     end
#
#     def read_multi(setting_definitions)
#       pipe.read_multi(setting_definitions)
#     end
#
#     def write(setting_definition, value, overrides, variants)
#       pipe.write(setting_definition, value, overrides, variants)
#     end
#   end
module Fino::Pipe
  def initialize(pipe)
    @pipe = pipe
  end

  # Reads a single setting through the pipeline.
  #
  # +setting_definition+ - A Fino::Definition::Setting instance.
  #
  # Returns a Fino::Setting instance.
  def read(setting_definition)
    raise NotImplementedError
  end

  # Reads multiple settings through the pipeline.
  #
  # +setting_definitions+ - An Array of Fino::Definition::Setting instances.
  #
  # Returns an Array of Fino::Setting instances.
  def read_multi(setting_definitions)
    raise NotImplementedError
  end

  # Writes a setting through the pipeline.
  #
  # +setting_definition+ - A Fino::Definition::Setting instance.
  # +value+ - The deserialized value.
  # +overrides+ - Hash of scope overrides.
  # +variants+ - Array of Fino::AbTesting::Variant instances.
  def write(setting_definition, value, overrides, variants)
    raise NotImplementedError
  end

  private

  attr_reader :pipe
end
