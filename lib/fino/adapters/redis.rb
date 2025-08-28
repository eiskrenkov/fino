# frozen_string_literal: true

class Fino::Adapters::Redis
  include Fino::Adapter

  def read_multi(_settings)
    rails.hmget("some")
  end
end
