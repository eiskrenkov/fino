# frozen_string_literal: true

class Fino::Cache::Memory
  include Fino::Cache

  def initialize(expires_in:)
    @hash = {}
    @expirator = Fino::Expirator.new(ttl: expires_in) if expires_in
  end

  def exist?(key)
    hash.key?(key)
  ensure
    expire_if_needed
  end

  def read(key)
    hash[key]
  ensure
    expire_if_needed
  end

  def write(key, value)
    hash[key] = value
  end

  def fetch(key, &block)
    hash.fetch(key) do
      write(key, block.call)
    end
  ensure
    expire_if_needed
  end

  def fetch_multi(keys, &block)
    missing_keys = keys - hash.keys

    if missing_keys.any?
      results = block.call(missing_keys)

      results.each do |key, value|
        write(key, value)
      end
    end

    hash.values_at(*keys)
  ensure
    expire_if_needed
  end

  def delete(key)
    hash.delete(key)
  end

  private

  attr_reader :hash, :expirator

  def expire_if_needed
    expirator&.when_ready do
      Fino.logger.debug { "Expiring all cache entries" }
      hash.clear
    end
  end
end
