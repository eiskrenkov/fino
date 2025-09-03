# frozen_string_literal: true

class Fino::Cache::Memory
  include Fino::Cache

  def initialize(expires_in:)
    @hash = {}
    @expirator = Fino::Expirator.new(ttl: expires_in)
  end

  def fetch(key, &)
    @hash.fetch(key, &)
  ensure
    @expirator.when_ready do
      @hash.clear
    end
  end

  def write(key, value)
    @hash[key] = value
  end
end
