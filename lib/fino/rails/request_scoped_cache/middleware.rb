# frozen_string_literal: true

class Fino::Rails::RequestScopedCache::Middleware
  def initialize(app)
    @app = app
  end

  def call(env)
    Fino::Rails::RequestScopedCache::Pipe.with_temporary_cache do
      @app.call(env)
    end
  end
end
