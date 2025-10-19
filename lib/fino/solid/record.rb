# frozen_string_literal: true

module Fino
  module Solid
    class Record < ActiveRecord::Base
      self.abstract_class = true

      connects_to(**Fino::Solid.connects_to) if Fino::Solid.connects_to
    end
  end
end
