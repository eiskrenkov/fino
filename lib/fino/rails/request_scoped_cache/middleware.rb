# frozen_string_literal: true

class Fino::Rails::RequestScopedCache::Middleware
  def initialize(app, options = {})
    @app = app
    @cache_wrapper_block = options[:cache_wrapper_block]
  end

  def call(env)
    Fino::Rails::RequestScopedCache::Pipe.with_temporary_cache(@cache_wrapper_block) do
      @app.call(env)
    end
  end
end
