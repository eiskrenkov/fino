# frozen_string_literal: true

# Abstract interface for cache implementations.
#
# Caching is optional in Fino. When configured, the cache sits in the pipeline
# between the library and the storage adapter, reducing round-trips for
# frequently read settings.
#
# == Built-in Implementation
#
# - Fino::Cache::Memory -- process-local in-memory cache with TTL support
#
# == Implementing a Custom Cache
#
#   class MyCache
#     include Fino::Cache
#
#     def read(key)    = @store[key]
#     def write(key, value) = (@store[key] = value)
#     def exist?(key)  = @store.key?(key)
#     def delete(key)  = @store.delete(key)
#     def clear        = @store.clear
#
#     def fetch(key, &block)
#       exist?(key) ? read(key) : write(key, block.call)
#     end
#
#     def fetch_multi(*keys, &block)
#       # ...
#     end
#   end
module Fino::Cache
  # Returns +true+ if the key exists in the cache.
  def exist?(key)
    raise NotImplementedError
  end

  # Returns the cached value for the key, or +nil+.
  def read(key)
    raise NotImplementedError
  end

  # Stores a value in the cache under the given key.
  def write(key, value)
    raise NotImplementedError
  end

  # Returns the cached value for the key, or calls the block, caches
  # the result, and returns it.
  def fetch(key, &)
    raise NotImplementedError
  end

  # Fetches multiple keys at once. Missing keys are resolved by calling
  # the block with an Array of missing keys; the block should return a
  # Hash of +{ key => value }+ pairs.
  def fetch_multi(*keys, &)
    raise NotImplementedError
  end

  # Removes a single key from the cache.
  def delete(key)
    raise NotImplementedError
  end

  # Removes all entries from the cache.
  def clear
    raise NotImplementedError
  end
end
