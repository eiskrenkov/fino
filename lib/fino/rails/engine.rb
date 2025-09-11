# frozen_string_literal: true

require "fino-rails"

class Fino::Rails::Engine < Rails::Engine
  isolate_namespace Fino::Rails

  #
  # Engine
  #

  paths["app"] << root.join("lib", "fino", "rails", "app")
  paths["config/initializers"] << root.join("lib", "fino", "rails", "config", "initializers")

  initializer "fino.rails.engine.views" do |_app|
    ActiveSupport.on_load :action_controller do
      prepend_view_path Fino::Rails::Engine.root.join("lib", "fino", "rails", "app", "views")
    end
  end

  initializer "fino.rails.engine.routes", before: :add_routing_paths do |app|
    custom_routes = root.join("lib", "fino", "rails", "config", "routes.rb")
    app.routes_reloader.paths << custom_routes.to_s
  end

  #
  # Configuration
  #

  config.before_configuration do
    config.fino = ActiveSupport::OrderedOptions.new.update(
      instrument: Rails.env.development?,
      log: Rails.env.development?
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
        if config.instrument
          wrap do |pipe|
            Fino::Rails::Instrumentation::Pipe.new(pipe)
          end
        end

        use Fino::Rails::RequestScopedCache::Pipe if defined?(Rails::Server)
      end
    end
  end

  initializer "fino.request_scoped_caching.middleware" do |app|
    app.middleware.use Fino::Rails::RequestScopedCache::Middleware if defined?(Rails::Server)
  end
end
