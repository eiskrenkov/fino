# frozen_string_literal: true

class Fino::Cache::Memory
  include Fino::Cache

  def initialize(expires_in:)
    @hash = {}
    @expirator = Fino::Expirator.new(ttl: expires_in) if expires_in
  end

  def exist?(key)
    expire_if_ready

    hash.key?(key)
  end

  def read(key)
    expire_if_ready

    hash[key]
  end

  def write(key, value)
    hash[key] = value
  end

  def fetch(key, &block)
    raise ArgumentError, "no block provided to #{self.class.name}#fetch" unless block

    expire_if_ready

    hash.fetch(key) do
      write(key, block.call)
    end
  end

  def fetch_multi(*keys, &block)
    raise ArgumentError, "no block provided to #{self.class.name}#fetch_multi" unless block

    expire_if_ready

    missing_keys = keys - hash.keys

    if missing_keys.any?
      results = block.call(missing_keys)

      results.each do |key, value|
        write(key, value)
      end
    end

    hash.values_at(*keys)
  end

  def delete(key)
    hash.delete(key)
  end

  def clear
    hash.clear
  end

  private

  attr_reader :hash, :expirator

  def expire_if_ready
    expirator&.when_ready do
      Fino.logger.debug { "Expiring all cache entries" }
      hash.clear
    end
  end
end
