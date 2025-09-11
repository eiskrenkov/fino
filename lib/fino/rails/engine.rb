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
  # Request scoped cache
  #

  initializer "fino.pipeline" do
    if defined?(Rails::Server)
      Fino.configure do
        pipeline do
          use Fino::Rails::RequestScopedCache::Pipe
        end
      end
    end
  end

  initializer "fino.middleware" do |app|
    app.middleware.use Fino::Rails::RequestScopedCache::Middleware if defined?(Rails::Server)
  end
end
