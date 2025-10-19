# frozen_string_literal: true

module Fino::CustomRedisScripts
  module_function

  def mapped_hreplace(connection, key, values_mapping)
    connection.del(key)
    connection.mapped_hmset(key, values_mapping)
  end

  refine Redis do
    def mapped_hreplace(key, values_mapping)
      multi do |multi|
        Fino::CustomRedisScripts.mapped_hreplace(multi, key, values_mapping)
      end
    end
  end

  refine Redis::MultiConnection do
    def mapped_hreplace(key, values_mapping)
      Fino::CustomRedisScripts.mapped_hreplace(self, key, values_mapping)
    end
  end
end
