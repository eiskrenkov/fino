# frozen_string_literal: true

require "fino-rails"

class Fino::Rails::Engine < Rails::Engine
  isolate_namespace Fino::Rails

  #
  # Engine
  #

  gem_root = root.join("lib", "fino", "rails")

  paths["app"] << gem_root.join("app")
  paths["config/initializers"] << gem_root.join("config", "initializers")

  initializer "fino.rails.engine.views" do |_app|
    ActiveSupport.on_load :action_controller do
      prepend_view_path gem_root.join("app", "views")
    end
  end

  initializer "fino.rails.engine.routes", before: :add_routing_paths do |app|
    custom_routes = gem_root.join("config", "routes.rb")
    app.routes_reloader.paths << custom_routes.to_s
  end

  initializer "fino.rails.engine.assets" do
    config.app_middleware.use(
      Rack::Static,
      urls: ["/fino-assets"],
      root: gem_root.join("public").to_s
    )
  end

  #
  # Configuration
  #

  config.before_configuration do
    config.fino = ActiveSupport::OrderedOptions.new.update(
      instrument: Rails.env.development?,
      log: Rails.env.development?,
      cache_within_request: true,
      preload_before_request: false
    )
  end

  #
  # Initializers
  #

  initializer "fino.log", after: :load_config_initializers do |app|
    config = app.config.fino

    require "fino/rails/instrumentation/log_subscriber" if config.instrument && config.log
  end

  initializer "fino.pipeline" do |app|
    config = app.config.fino

    Fino.configure do
      pipeline do
        use Fino::Rails::RequestScopedCache::Pipe if defined?(Rails::Server) && config.cache_within_request
      end

      if config.instrument
        wrap_adapter do |adapter|
          Fino::Rails::Instrumentation::Adapter.new(adapter)
        end

        wrap_cache do |cache|
          Fino::Rails::Instrumentation::Cache.new(cache)
        end
      end
    end
  end

  initializer "fino.request_scoped_caching.middleware" do |app|
    config = app.config.fino

    if defined?(Rails::Server)
      if config.cache_within_request
        cache_wrapper_block = if config.instrument
                                proc { |cache| Fino::Rails::Instrumentation::Cache.new(cache) }
                              else
                                proc { |cache| cache }
                              end

        app.middleware.use Fino::Rails::RequestScopedCache::Middleware, cache_wrapper_block: cache_wrapper_block
      end

      if config.preload_before_request
        app.middleware.use Fino::Rails::Preloading::Middleware,
                           preload: config.preload_before_request
      end
    end
  end
end
