# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

# module Fino::Settings::Definition
#   def initialize(key, section)
#   end

#   def value

#   end
# end

# class Fino::Settings::Definition::String
#   include Fino::Settings::Definition
# end

# class Fino::Adapters::Solid
# end

module Fino
  extend self

  def library
    Thread.current[:fino_library] ||= Fino::Library.new
  end

  def configure(&)
    yield(configuration)
  end

  def settings(&)
    section_dsl.instance_eval(&)
  end

  def section_dsl
    @section_dsl = Fino::Registry::DSL.new(registry)
  end

  def registry
    @registry ||= Fino::Registry.new
  end

  def setting(setting_name, section_name)
    library.read(setting_name.to_s, section_name.to_s)
  end

  private

  def configuration
    @configuration ||= Configuration.new(registry)
  end
end
