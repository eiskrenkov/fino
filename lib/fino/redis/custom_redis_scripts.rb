# frozen_string_literal: true

module Fino::CustomRedisScripts
  refine Redis do
    def mapped_hreplace(key, values_mapping)
      multi do |r|
        r.del(key)
        r.mapped_hmset(key, values_mapping)
      end
    end
  end
end
