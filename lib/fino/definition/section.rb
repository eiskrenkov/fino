# frozen_string_literal: true

# Describes a settings section (a named group of related settings).
#
# Sections are defined in the configuration DSL and stored in the
# Fino::Registry. They provide logical grouping and a display label
# for UI purposes.
#
#   section :openai, label: "OpenAI" do
#     setting :model, :string, default: "gpt-5"
#   end
class Fino::Definition::Section
  # Returns the Symbol name of the section.
  attr_reader :name

  # Returns the Hash of additional options (e.g. +label:+).
  attr_reader :options

  def initialize(name:, **options)
    @name = name
    @options = options
  end

  # Returns the display label for this section.
  #
  # Falls back to the capitalized section name if no +:label+ option was provided.
  def label
    options.fetch(:label, name.to_s.capitalize)
  end

  # Two sections are equal if they have the same class and name.
  def eql?(other)
    self.class.eql?(other.class) && name == other.name
  end
  alias == eql?

  # Hash code based on the name, for use in Sets and Hash keys.
  def hash
    name.hash
  end
end
