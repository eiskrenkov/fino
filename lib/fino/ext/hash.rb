# frozen_string_literal: true

module Fino::Ext::Hash
  refine Hash do
    def deep_set(value, *path)
      item = path.pop

      if path.empty?
        self[item] = value
      else
        (self[item] ||= {}).deep_set(value, *path)
      end
    end
  end
end
