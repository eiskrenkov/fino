# frozen_string_literal: true

# Process-local in-memory cache with TTL-based expiration.
#
# Stores settings in a plain Hash and expires all entries once the TTL
# elapses. Because this cache is not distributed, each process holds its
# own copy; setting updates take effect after the TTL expires.
#
# == Usage
#
#   Fino.configure do
#     cache { Fino::Cache::Memory.new(expires_in: 3) }
#   end
#
# +expires_in+ - Numeric TTL in seconds. All entries are cleared when the
#                TTL elapses.
class Fino::Cache::Memory
  include Fino::Cache

  def initialize(expires_in:)
    @hash = {}
    @expirator = Fino::Expirator.new(ttl: expires_in) if expires_in
  end

  # Returns +true+ if the key is present (checking expiration first).
  def exist?(key)
    expire_if_ready

    hash.key?(key)
  end

  # Returns the cached value, or +nil+ (checking expiration first).
  def read(key)
    expire_if_ready

    hash[key]
  end

  # Stores a value under the given key.
  def write(key, value)
    hash[key] = value
  end

  # Returns the cached value for +key+, or calls the block, caches and
  # returns the result.
  #
  # Raises +ArgumentError+ if no block is given.
  def fetch(key, &block)
    raise ArgumentError, "no block provided to #{self.class.name}#fetch" unless block

    expire_if_ready

    hash.fetch(key) do
      write(key, block.call)
    end
  end

  # Fetches multiple keys. Missing keys are resolved by the block, which
  # receives an Array of missing keys and should return a Hash of results.
  #
  # Raises +ArgumentError+ if no block is given.
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

  # Removes a single key from the cache.
  def delete(key)
    hash.delete(key)
  end

  # Clears all cached entries.
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
