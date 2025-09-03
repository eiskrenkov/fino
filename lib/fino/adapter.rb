# frozen_string_literal: true

module Fino::Adapter
  def read(setting_definition)
    raise NotImplementedError
  end

  def read_multi(setting_definitions)
    raise NotImplementedError
  end

  def write(setting_definition, value)
    raise NotImplementedError
  end
end
