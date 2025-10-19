# frozen_string_literal: true

module Fino
  module Solid
    class Setting < Record
      self.table_name = "fino_settings"

      serialize :data, coder: JSON

      validates :key, presence: true, uniqueness: true
    end
  end
end
